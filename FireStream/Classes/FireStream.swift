//
//  FireStream.swift
//  FireStream
//
//  Created by Pepe Becker on 2/4/20.
//

import RxSwift
import FirebaseAuth

public class FireStream: AbstractChat, PFireStream {

    static internal let instance = FireStream()

    internal var user: User?

    internal var contacts = [FireStreamUser]()
    internal var blocked = [FireStreamUser]()
    internal var muted = [String: Date]()

    internal var chatEvents = MultiQueueSubject<FireStreamEvent<Chat>>()
    internal var contactEvents = MultiQueueSubject<FireStreamEvent<FireStreamUser>>()
    internal var blockedEvents = MultiQueueSubject<FireStreamEvent<FireStreamUser>>()

    internal var connectionEvents = BehaviorSubject<ConnectionEvent>(value: ConnectionEvent(.None))

    internal var firebaseService: FirebaseService?

    internal var markReceivedFilter: Predicate<FireStreamEvent<Message>>?

    /**
     * Current configuration
     */
    internal var config: Config?

    public class func shared() -> FireStream {
        return self.instance
    }

    internal var chats = [PChat]()

    public override init() {
        super.init()
    }

    public func initialize(_ config: Config?) {
        if let config = config {
            self.config = config
        } else {
            self.config = Config()
        }

        if self.config?.database == .Firestore {
            self.firebaseService = FirestoreService()
        }
        if self.config?.database == .Realtime {
            self.firebaseService = RealtimeService()
        }

        self.markReceivedFilter = { message in
            guard let config = self.config else {
                return false
            }
            return config.deliveryReceiptsEnabled && config.autoMarkReceived
        }

        Auth.auth().addStateDidChangeListener { (auth, user) in
            // We are connecting for the first time
            if self.user == nil, let user = Auth.auth().currentUser {
                self.user = user
                do {
                    try self.connect()
                } catch {
                    self.events.publishThrowable().onNext(error)
                }
            }
            if self.user != nil && Auth.auth().currentUser == nil {
                self.user = nil
                self.disconnect()
            }
        }
    }

    public func initialize() {
        initialize(nil)
    }

    public func isInitialized() -> Bool {
        return self.config != nil
    }

    public override func connect() throws {

        guard let config = self.config else {
            throw FireStreamError("You need to call Fire.stream().initialize(…)")
        }
        if self.user == nil {
            throw FireStreamError("Firebase must be authenticated to connect")
        }

        connectionEvents.onNext(ConnectionEvent.willConnect())

        // MESSAGE DELETION

        // We always delete typing state and presence messages
        var stream = getSendableEvents().getSendables().allEvents()
        if (!config.deleteMessagesOnReceipt) {
            stream = stream.filter(Filter.eventBySendableType(SendableType.typingState(), SendableType.presence()));
        }
        // If deletion is enabled, we don't filter so we delete all the message types
        dm.add(stream.map { $0.get() }
            .flatMap { self.deleteSendable($0) }
            .subscribe())

        // DELIVERY RECEIPTS

        dm.add(getSendableEvents()
                .getMessages()
                .allEvents()
                .filter(deliveryReceiptFilter())
                .flatMap { self.markReceived($0.get()) }
                .do(onError: self.accept)
                .subscribe())

        // If message deletion is disabled, send a received receipt to ourself for each message. This means
        // that when we add a childListener, we only get new messages
        if !config.deleteMessagesOnReceipt && config.startListeningFromLastSentMessageDate {
            dm.add(getSendableEvents()
                .getMessages()
                .allEvents()
                .filter(Filter.notFromMe())
                .flatMap { self.sendDeliveryReceipt(self.currentUserId(), DeliveryReceiptType.received(), $0.get()?.getId()) }
                .do(onError: self.accept)
                .subscribe())
        }

        // INVITATIONS

        dm.add(getSendableEvents().getInvitations().allEvents().flatMap { event -> Completable in
            if config.autoAcceptChatInvite {
                return event.get()?.accept() ?? Completable.empty()
            }
            return Completable.empty()
        }.do(onError: self.accept).subscribe())

        // BLOCKED USERS

        dm.add(listChangeOn(Paths.blockedPath()).subscribe(onNext: { listEvent in
            do {
                let ue = listEvent.to(try FireStreamUser.from(listEvent))
                if ue.typeIs(EventType.Added), let u = ue.get() {
                    self.blocked.append(u)
                }
                if ue.typeIs(EventType.Removed), let u = ue.get() {
                    self.blocked.removeAll { $0.id == u.id }
                }
                self.blockedEvents.onNext(ue)
            } catch {
                self.accept(error)
            }
        }))

        // CONTACTS

        dm.add(listChangeOn(Paths.contactsPath()).subscribe(onNext: { listEvent in
            do {
                let ue = listEvent.to(try FireStreamUser.from(listEvent))
                if ue.typeIs(EventType.Added), let u = ue.get() {
                    self.contacts.append(u)
                }
                if ue.typeIs(EventType.Removed), let u = ue.get() {
                    self.contacts.removeAll { $0.id == u.id }
                }
                self.contactEvents.onNext(ue)
            } catch {
                self.accept(error)
            }
        }));

        // CONNECT TO EXISTING GROUP CHATS

        dm.add(listChangeOn(Paths.userChatsPath()).subscribe(onNext: { listEvent in
            do {
                let chatEvent = listEvent.to(try Chat.from(listEvent))
                if let chat = chatEvent.get() {
                    if chatEvent.typeIs(EventType.Added) {
                        try chat.connect()
                        self.chats.append(chat)
                        self.chatEvents.onNext(chatEvent)
                    }
                    else if chatEvent.typeIs(EventType.Removed) {
                        self.dm.add(chat.leave().subscribe(onCompleted: {
                            self.chats.removeAll { $0.getId() == chat.id }
                            self.chatEvents.onNext(chatEvent)
                        }, onError: self.accept))
                    } else {
                        self.chatEvents.onNext(chatEvent)
                    }
                }
            } catch {
                self.accept(error)
            }
        }));

        dm.add(listChangeOn(Paths.userMutedPath()).subscribe(onNext: { listDataEvent in
            if let id = listDataEvent.get()?.getId() {
                if listDataEvent.typeIs(EventType.Removed) {
                    self.muted.removeValue(forKey: id)
                } else if let data = listDataEvent.get()?.getData() {
                    if let date = data[Keys.Date] as? Date {
                        self.muted[id] = date
                    } else if let interval = data[Keys.Date] as? TimeInterval {
                        self.muted[id] = Date(timeIntervalSince1970: interval)
                    }
                }
            }
        }))

        // Connect to the message events AFTER we have added our events listeners
        try super.connect()

        self.connectionEvents.onNext(ConnectionEvent.didConnect())
    }

    public override func disconnect() {
        self.connectionEvents.onNext(ConnectionEvent.willDisconnect())
        super.disconnect()
        self.connectionEvents.onNext(ConnectionEvent.didDisconnect())
    }

    public func currentUserId() -> String? {
        return self.user?.uid
    }

    //
    // Messages
    //

    public func deleteSendable(_ sendable: Sendable?) -> Completable {
        if let sendableId = sendable?.getId() {
            return deleteSendable(sendableId)
        } else {
            return Completable.empty()
        }
    }

    public func deleteSendable(_ sendableId: String) -> Completable {
        return deleteSendable(Paths.messagePath(sendableId))
    }

    public func sendPresence(_ userId: String, _ type: PresenceType) -> Completable {
        return sendPresence(userId, type, nil)
    }

    public func sendPresence(_ userId: String, _ type: PresenceType, _ newId: Consumer<String>?) -> Completable {
        return send(userId, Presence(type), newId)
    }


    public func sendInvitation(_ userId: String, _ type: InvitationType, _ id: String) -> Completable {
        return sendInvitation(userId, type, id, nil)
    }

    public func sendInvitation(_ userId: String, _ type: InvitationType, _ groupId: String, _ newId: Consumer<String>?) -> Completable {
        return send(userId, Invitation(type, groupId), newId)
    }

    public func send(_ toUserId: String, _ sendable: Sendable) -> Completable {
        return send(toUserId, sendable, nil)
    }

    public func send(_ toUserId: String, _ sendable: Sendable, _ newId: Consumer<String>?) -> Completable {
        return send(Paths.messagesPath(toUserId), sendable, newId)
    }

    public func sendDeliveryReceipt(_ userId: String?, _ type: DeliveryReceiptType?, _ messageId: String?) -> Completable {
        return sendDeliveryReceipt(userId, type, messageId, nil)
    }

    public func sendDeliveryReceipt(_ userId: String?, _ type: DeliveryReceiptType?, _ messageId: String?, _ newId: Consumer<String>?) -> Completable {
        guard let userId = userId else {
            return Completable.error(FireStreamError("userId is nil"))
        }
        guard let type = type else {
            return Completable.error(FireStreamError("type is nil"))
        }
        guard let messageId = messageId else {
            return Completable.error(FireStreamError("messageId is nil"))
        }
        return send(userId, DeliveryReceipt(type, messageId), newId)
    }

    public func sendTypingIndicator(_ userId: String, _ type: TypingStateType) -> Completable {
        return sendTypingIndicator(userId, type, nil)
    }

    public func sendTypingIndicator(_ userId: String, _ type: TypingStateType, _ newId: Consumer<String>?) -> Completable {
        return send(userId, TypingState(type), newId)
    }

    public func sendMessageWithText(_ userId: String, _ text: String) -> Completable {
        return sendMessageWithText(userId, text, nil)
    }

    public func sendMessageWithText(_ userId: String, _ text: String, _ newId: Consumer<String>?) -> Completable {
        return send(userId, TextMessage(text), newId)
    }

    public func sendMessageWithBody(_ userId: String, _ body: [String: Any]) -> Completable {
        return sendMessageWithBody(userId, body, nil)
    }

    public func sendMessageWithBody(_ userId: String, _ body: [String: Any], _ newId: Consumer<String>?) -> Completable {
        return send(userId, Message(body), newId)
    }

    //
    // Blocking
    //

    public func block(_ user: FireStreamUser) -> Completable {
        return addUser(Paths.blockedPath(), FireStreamUser.dateDataProvider(), user)
    }

    public func unblock(_ user: FireStreamUser) -> Completable {
        return removeUser(Paths.blockedPath(), user)
    }

    public func getBlocked() -> [FireStreamUser] {
        return self.blocked
    }

    public func isBlocked(_ user: FireStreamUser) -> Bool {
        return self.blocked.contains { $0.id == user.id }
    }

    //
    // Contacts
    //

    public func addContact(_ user: FireStreamUser, _ type: ContactType) -> Completable {
        user.setContactType(type)
        return addUser(Paths.contactsPath(), FireStreamUser.contactTypeDataProvider(), user)
    }

    public func removeContact(_ user: FireStreamUser) -> Completable {
        return removeUser(Paths.contactsPath(), user);
    }

    public func getContacts() -> [FireStreamUser] {
        return self.contacts
    }

    //
    // Chats
    //

    public func createChat(_ name: String?, _ imageURL: String?, _ users: FireStreamUser...) -> Single<Chat> {
        return createChat(name, imageURL, nil, users)
    }

    public func createChat(_ name: String?, _ imageURL: String?, _ customData: [String: Any]?, _ users: FireStreamUser...) -> Single<Chat> {
        return createChat(name, imageURL, customData, users)
    }

    public func createChat(_ name: String?, _ imageURL: String?, _ users: [FireStreamUser]) -> Single<Chat> {
        return createChat(name, imageURL, nil, users)
    }

    public func createChat(_ name: String?, _ imageURL: String?, _ customData: [String: Any]?, _ users: [FireStreamUser]) -> Single<Chat> {
        return Chat.create(name, imageURL, customData, users).flatMap { chat in
            return self.joinChat(chat).andThen(Single.just(chat))
        }
    }

    public func getChat(_ chatId: String) -> PChat? {
        for chat in chats {
            if chat.getId() == chatId {
                return chat
            }
        }
        return nil
    }

    public func leaveChat(_ chat: PChat) -> Completable {
        // We remove the chat from our list of chats, when that completes,
        // we will remove our self from the chat roster
        guard let firebaseService = getFirebaseService() else {
            return Completable.empty()
        }
        return firebaseService.chat.leaveChat(chat.getId())
                .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
                .observeOn(MainScheduler.instance)
    }

    public func joinChat(_ chat: PChat) -> Completable {
        guard let firebaseService = getFirebaseService() else {
            return Completable.empty()
        }
        return firebaseService.chat
                .joinChat(chat.getId())
                .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
                .observeOn(MainScheduler.instance)
    }

    public func getChats() -> [PChat] {
        return self.chats
    }

    /**
     * Send a read receipt
     * @return completion
     */
    public override func markRead(_ sendable: Sendable?) -> Completable {
        if let from = sendable?.getFrom(), let sendableId = sendable?.getId() {
            return markRead(from, sendableId)
        } else {
            return Completable.empty()
        }
    }

    public func markRead(_ fromUserId: String, _ sendableId: String) -> Completable {
        return sendDeliveryReceipt(fromUserId, DeliveryReceiptType.read(), sendableId)
    }

    /**
     * Send a received receipt
     * @return completion
     */
    public override func markReceived(_ sendable: Sendable?) -> Completable {
        if let from = sendable?.getFrom(), let sendableId = sendable?.getId() {
            return markReceived(from, sendableId)
        } else {
            return Completable.empty()
        }
    }

    public func markReceived(_ fromUserId: String, _ sendableId: String) -> Completable {
        return sendDeliveryReceipt(fromUserId, DeliveryReceiptType.received(), sendableId)
    }

    //
    // Events
    //

    public func getChatEvents() -> MultiQueueSubject<FireStreamEvent<Chat>> {
        return self.chatEvents
    }

    public func getBlockedEvents() -> MultiQueueSubject<FireStreamEvent<FireStreamUser>> {
        return self.blockedEvents
    }

    public func getContactEvents() -> MultiQueueSubject<FireStreamEvent<FireStreamUser>> {
        return self.contactEvents
    }

    public func getConnectionEvents() -> Observable<ConnectionEvent> {
        return self.connectionEvents
    }

    //
    // Utility
    //

    internal override func dateOfLastDeliveryReceipt() -> Single<Date> {
        if let config = self.config, config.deleteMessagesOnReceipt {
            return Single.just(config.listenToMessagesWithTimeAgo.getDate());
        } else {
            return super.dateOfLastDeliveryReceipt();
        }
    }

    public func currentUser() -> FireStreamUser? {
        if let uid = currentUserId() {
            return FireStreamUser(uid)
        }
        return nil
    }

    internal override func messagesPath() -> Path? {
        return Paths.messagesPath()
    }

    public func getConfig() -> Config? {
        return self.config
    }

    public func getFirebaseService() -> FirebaseService? {
        return self.firebaseService
    }

    public func setMarkReceivedFilter(_ filter: @escaping Predicate<FireStreamEvent<Message>>) {
        self.markReceivedFilter = filter
    }

    public func getMarkReceivedFilter() -> Predicate<FireStreamEvent<Message>>? {
        return self.markReceivedFilter
    }

    public func mute(_ user: FireStreamUser) -> Completable {
        return mute(user, nil)
    }

    public func mute(_ user: FireStreamUser, _ until: Date?) -> Completable {
        return mute(user.getId(), until)
    }

    public func unmute(_ user: FireStreamUser) -> Completable {
        return mute(user, nil)
    }

    public func mutedUntil(_ user: FireStreamUser) -> Date? {
        return mutedUntil(user.getId())
    }

    public func muted(_ user: FireStreamUser) -> Bool {
        return muted(user.getId())
    }

    // Internal mute methods

    public func mutedUntil(_ id: String) -> Date? {
        return self.muted[id]
    }

    public func muted(_ id: String) -> Bool {
        return mutedUntil(id) != nil
    }

    public func mute(_ id: String) -> Completable {
        return mute(id, nil)
    }

    public func mute(_ id: String, _ until: Date?) -> Completable {
        guard let firebaseService = getFirebaseService() else {
            return Completable.error(getFirebaseServiceNilError())
        }

        guard let userMutedPath = Paths.userMutedPath() else {
            return Completable.error(FireStreamError("userMutedPath is nil"))
        }

        return firebaseService.core.mute(userMutedPath.child(id), [
            Keys.Date: until?.timeIntervalSince1970 ?? Int.max
        ])
    }

    public func unmute(_ id: String) -> Completable {
        guard let firebaseService = getFirebaseService() else {
            return Completable.error(getFirebaseServiceNilError())
        }

        guard let userMutedPath = Paths.userMutedPath() else {
            return Completable.error(FireStreamError("userMutedPath is nil"))
        }

        return firebaseService.core.unmute(userMutedPath.child(id))
    }

    public func getConfigNilError() -> Error {
        return FireStreamError("Config is nil")
    }

    public func getFirebaseServiceNilError() -> Error {
        return FireStreamError("FirebaseService is nil")
    }

}
