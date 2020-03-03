//
//  Chat.swift
//  FireStream
//
//  Created by Pepe Becker on 2/11/20.
//

import RxSwift

public class Chat: AbstractChat, PChat {

    internal var id: String
    internal var joined: Date?
    internal var meta = Meta()

    internal var users = [FireStreamUser]()
    internal var userEvents = MultiQueueSubject<FireStreamEvent<FireStreamUser>>()

    internal var nameChangedEvents = BehaviorSubject<String>(value: "")
    internal var imageURLChangedEvents = BehaviorSubject<String>(value: "")
    internal var customDataChangedEvents = BehaviorSubject<[String: Any]>(value: [:])

    public init(_ id: String) {
        self.id = id
    }

    public convenience init(_ id: String, _ joined: Date?, _ meta: Meta) {
        self.init(id, joined)
        self.meta = meta
    }

    public convenience init(_ id: String, _ joined: Date?) {
        self.init(id)
        self.joined = joined
    }

    public func getId() -> String {
        return self.id
    }

    public override func connect() throws {

        debug("Connect to chat: " + id)

        // If delivery receipts are enabled, send the delivery receipt
        if let config = Fire.internalApi().getConfig(), config.deliveryReceiptsEnabled {
            dm.add(getSendableEvents()
                .getMessages()
                .allEvents()
                .filter(deliveryReceiptFilter())
                .flatMap { self.markReceived($0.get()) }
                .do(onError: accept)
                .subscribe())
        }

        dm.add(listChangeOn(Paths.chatUsersPath(id)).subscribe(onNext: { listEvent in
            do {
                let userEvent = listEvent.to(try FireStreamUser.from(listEvent))
                let user = userEvent.get()

                // If we start by removing the user. If it type a remove event
                // we leave it at that. Otherwise we add that user back in
                self.users.removeAll { $0.id == user?.id }
                if !userEvent.typeIs(EventType.Removed), let user = user {
                    self.users.append(user)
                }

                self.userEvents.onNext(userEvent)
            } catch {

            }
        }))

        // Handle name and image change
        if let firebaseService = Fire.internalApi().getFirebaseService() {
            dm.add(firebaseService.chat
                .metaOn(getId())
                .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { newMeta in
                    if newMeta.getName().count > 0 && newMeta.getName() != self.meta.getName() {
                        _ = self.meta.setName(newMeta.name)
                        self.nameChangedEvents.onNext(self.meta.getName())
                    }
                    if newMeta.getImageURL().count > 0 && newMeta.getImageURL() != self.meta.getImageURL() {
                        _ = self.meta.setImageURL(newMeta.imageURL)
                        self.imageURLChangedEvents.onNext(self.meta.getImageURL())
                    }
                    if let data = newMeta.getData() {
                        _ = self.meta.setData(data)
                        self.customDataChangedEvents.onNext(data)
                    }
                    if let created = newMeta.getCreated() {
                        _ = self.meta.setCreated(created)
                    }
                }, onError: self.accept))
        }

        try super.connect()
    }

    public func leave() -> Completable {
        return Completable.deferred {
            if let rt = self.getMyRoleType(), rt.equals(RoleType.owner()) && self.getUsers().count > 1 {
                if self.getUsers().count > 1 {
                    return Completable.error(FireStreamError("Remove the other users before you can delete the group"))
                } else {
                    return self.delete().do(onCompleted: self.disconnect)
                }
            }
            return self.removeUser(FireStreamUser.currentUser()).do(onCompleted: self.disconnect)
        }
    }

    internal func delete() -> Completable {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Completable.error(Fire.internalApi().getFirebaseServiceNilError())
        }
        return firebaseService.chat.delete(getId())
    }

    public func getName() -> String {
        return meta.getName()
    }

    public func setName(_ name: String) -> Completable {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Completable.error(Fire.internalApi().getFirebaseServiceNilError())
        }
        if !hasPermission(RoleType.admin()) {
            return Completable.error(self.adminPermissionRequired())
        } else if self.meta.getName() == name {
            return Completable.empty()
        } else {
            return firebaseService.chat.setMetaField(getId(), Keys.Name, name).do(onCompleted: {
                _ = self.meta.setName(name)
            })
        }
    }

    public func getImageURL() -> String {
        return self.meta.getImageURL()
    }

    public func setImageURL(_ url: String) -> Completable {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Completable.error(Fire.internalApi().getFirebaseServiceNilError())
        }
        if !hasPermission(RoleType.admin()) {
            return Completable.error(self.adminPermissionRequired())
        } else if self.meta.getImageURL() == url {
            return Completable.empty()
        } else {
            return firebaseService.chat.setMetaField(getId(), Keys.ImageURL, url).do(onCompleted: {
                _ = self.meta.setImageURL(url)
            })
        }
    }

    public func getCustomData() -> [String: Any]? {
        return self.meta.getData()
    }

    public func setCustomData(_ data: [String: Any]?) -> Completable {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Completable.error(Fire.internalApi().getFirebaseServiceNilError())
        }
        if !hasPermission(RoleType.admin()) {
            return Completable.error(self.adminPermissionRequired())
        } else {
            return firebaseService.chat.setMetaField(getId(), Paths.Data, data).do(onCompleted: {
                _ = self.meta.setData(data)
            })
        }
    }

    public func getUsers() -> [FireStreamUser] {
        return self.users
    }

    public func addUser(_ sendInvite: Bool, _ user: FireStreamUser) -> Completable {
        return addUsers(sendInvite, user)
    }

    public func addUsers(_ sendInvite: Bool, _ users: FireStreamUser...) -> Completable {
        return addUsers(sendInvite, users)
    }

    public func addUsers(_ sendInvite: Bool, _ users: [FireStreamUser]) -> Completable {
        return addUsers(Paths.chatUsersPath(id), FireStreamUser.roleTypeDataProvider(), users)
            .concat(sendInvite ? inviteUsers(users) : Completable.empty())
            .do(onCompleted: { self.users.append(contentsOf: users) })
    }

    public func updateUser(_ user: FireStreamUser) -> Completable {
        return updateUser(Paths.chatUsersPath(id), FireStreamUser.roleTypeDataProvider(), user)
    }

    public func updateUsers(_ users: [FireStreamUser]) -> Completable {
        return updateUsers(Paths.chatUsersPath(id), FireStreamUser.roleTypeDataProvider(), users)
    }

    public func updateUsers(_ users: FireStreamUser...) -> Completable {
        return updateUsers(Paths.chatUsersPath(id), FireStreamUser.roleTypeDataProvider(), users)
    }

    public func removeUser(_ user: FireStreamUser?) -> Completable {
        return removeUser(Paths.chatUsersPath(id), user)
    }

    public func removeUsers(_ user: FireStreamUser...) -> Completable {
        return removeUsers(Paths.chatUsersPath(id), user)
    }

    public func removeUsers(_ users: [FireStreamUser]) -> Completable {
        return removeUsers(Paths.chatUsersPath(id), users)
    }

    public func inviteUsers(_ users: [FireStreamUser]) -> Completable {
        var completables = [Completable]()
        for user in users {
            if !user.isMe() {
                completables.append(Fire.stream().sendInvitation(user.id, InvitationType.chat(), id))
            }
        }
        return Completable.zip(completables)
            .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
            .observeOn(MainScheduler.instance)
    }

    public func getUsersForRoleType(_ roleType: RoleType) -> [FireStreamUser] {
        var result = [FireStreamUser]()
        for user in self.users {
            if let rt = user.roleType, rt.equals(roleType) {
                result.append(user)
            }
        }
        return result
    }

    public func setRole(_ user: FireStreamUser, _ roleType: RoleType) -> Completable {
        if roleType.equals(RoleType.owner()) && !hasPermission(RoleType.owner()) {
            return Completable.error(self.ownerPermissionRequired())
        } else if !hasPermission(RoleType.admin()) {
            return Completable.error(self.adminPermissionRequired())
        }
        user.roleType = roleType
        return updateUser(user)
    }

    public func getRoleType(_ theUser: FireStreamUser?) -> RoleType? {
        for user in self.users {
            if user.equals(theUser) {
                return user.roleType
            }
        }
        return nil
    }

    public func getAvailableRoles(_ user: FireStreamUser) -> [RoleType] {
        // We can't set our own role and only admins and higher can set a role
        if !user.isMe() && hasPermission(RoleType.admin()) {
            // The owner can set users to any role apart from owner
            if hasPermission(RoleType.owner()) {
                return RoleType.allExcluding(RoleType.owner())
            }
            // Admins can set the role type of non-admin users. They can't create or
            // destroy admins, only the owner can do that
            if let rt = user.roleType, rt.equals(RoleType.admin()) {
                return RoleType.allExcluding(RoleType.owner(), RoleType.admin())
            }
        }
        return []
    }

    public func getNameChangeEvents() -> Observable<String> {
        return nameChangedEvents
    }

    public func getImageURLChangeEvents() -> Observable<String> {
        return imageURLChangedEvents
    }

    public func getCustomDataChangedEvents() -> Observable<[String: Any]> {
        return customDataChangedEvents
    }

    public func getUserEvents() -> MultiQueueSubject<FireStreamEvent<FireStreamUser>> {
        return self.userEvents
    }

    public func sendMessageWithBody(_ body: [String: Any]) -> Completable {
        return sendMessageWithBody(body, nil)
    }

    public func sendMessageWithBody(_ body: [String: Any], _ newId: Consumer<String>?) -> Completable {
        return send(Message(body), newId)
    }

    public func sendMessageWithText(_ text: String) -> Completable {
        return sendMessageWithText(text, nil)
    }

    public func sendMessageWithText(_ text: String, _ newId: Consumer<String>?) -> Completable {
        return send(TextMessage(text), newId)
    }

    public func sendTypingIndicator(_ type: TypingStateType) -> Completable {
        return sendTypingIndicator(type, nil)
    }

    public func sendTypingIndicator(_ type: TypingStateType, _ newId: Consumer<String>?) -> Completable {
        return send(TypingState(type), newId)
    }

    public func sendDeliveryReceipt(_ type: DeliveryReceiptType, _ messageId: String) -> Completable {
        return sendDeliveryReceipt(type, messageId, nil)
    }

    public func sendDeliveryReceipt(_ type: DeliveryReceiptType, _ messageId: String, _ newId: Consumer<String>?) -> Completable {
        return send(DeliveryReceipt(type, messageId), newId)
    }

    public func send(_ sendable: Sendable, _ newId: Consumer<String>?) -> Completable {
        if !hasPermission(RoleType.member()) {
            return Completable.error(self.memberPermissionRequired())
        }
        return send(Paths.chatMessagesPath(id), sendable, newId)
    }

    public func send(_ sendable: Sendable) -> Completable {
        return send(sendable, nil)
    }

    public override func markReceived(_ sendable: Sendable?) -> Completable {
        return markReceived(sendable?.getId())
    }

    public func markReceived(_ sendableId: String?) -> Completable {
        if let sendableId = sendableId {
            return sendDeliveryReceipt(DeliveryReceiptType.received(), sendableId)
        } else {
            return Completable.error(FireStreamError("sendableId is nil"))
        }
    }

    public override func markRead(_ sendable: Sendable?) -> Completable {
        return markRead(sendable?.getId())
    }

    public func markRead(_ sendableId: String?) -> Completable {
        if let sendableId = sendableId {
            return sendDeliveryReceipt(DeliveryReceiptType.read(), sendableId)
        } else {
            return Completable.error(FireStreamError("sendableId is nil"))
        }
    }

    public func getMyRoleType() -> RoleType? {
        return getRoleType(Fire.stream().currentUser())
    }

    public func equals(_ chat: Chat) -> Bool {
        return self.id == chat.id
    }

    internal func setMeta(_ meta: Meta) {
        self.meta = meta
    }

    public func path() -> Path? {
        return Paths.chatPath(id)
    }

    public func metaPath() -> Path? {
        return Paths.chatMetaPath(id)
    }

    internal override func messagesPath() -> Path? {
        return Paths.chatMessagesPath(id)
    }

    internal func ownerPermissionRequired() -> Error {
        return FireStreamError("You must be a group owner to perform this action")
    }

    internal func adminPermissionRequired() -> Error {
        return FireStreamError("You must be a group admin to perform this action")
    }

    internal func memberPermissionRequired() -> Error {
        return FireStreamError("You must be a group member to perform this action")
    }

    public class func create(_ name: String?, _ imageURL: String?, _ data: [String: Any]?, _ users: [FireStreamUser]?) -> Single<Chat> {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Single.error(Fire.internalApi().getFirebaseServiceNilError())
        }
        guard let name = name else {
            return Single.error(FireStreamError("name is nil"))
        }
        guard let imageURL = imageURL else {
            return Single.error(FireStreamError("imageURL is nil"))
        }
        guard let data = data else {
            return Single.error(FireStreamError("data is nil"))
        }
        let meta = Meta.from(name, imageURL, data).addTimestamp().wrap().toData()
        return firebaseService.chat.add(meta).flatMap { chatId in
            let chat = Chat(chatId, nil, Meta(name, imageURL, data))

            var usersToAdd = [FireStreamUser](users ?? [])

            // Make sure the current user type the owner
            usersToAdd.removeAll { $0.id == FireStreamUser.currentUser()?.id }
            if let user = FireStreamUser.currentUser(RoleType.owner()) {
                usersToAdd.append(user)
            }

            return chat.addUsers(true, usersToAdd).andThen(Single.just(chat))
        }
        .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
        .observeOn(MainScheduler.instance)
    }

    public func hasPermission(_ required: RoleType) -> Bool {
        if let myRoleType = getMyRoleType() {
            return myRoleType.ge(required)
        }
        return false
    }

    public func deleteSendable(_ sendable: Sendable) -> Completable {
        return deleteSendable(sendable.getId())
    }

    public func deleteSendable(_ sendableId: String?) -> Completable {
        guard let sendableId = sendableId else {
            return Completable.error(FireStreamError("sendableId is nil"))
        }

        guard let messagesPath = messagesPath() else {
            return Completable.error(FireStreamError("messagesPath is nil"))
        }

        return deleteSendable(messagesPath.child(sendableId))
    }

    public class func from(_ listEvent: FireStreamEvent<ListData>) throws -> Chat {
        if let change = listEvent.get() {
            return Chat(change.getId(), change.get(Keys.Date) as? Date)
        } else {
            throw FireStreamError("Could not create chat")
        }
    }

    public func mute() -> Completable {
        return Fire.internalApi().mute(getId())
    }

    public func mute(_ until: Date?) -> Completable {
        return Fire.internalApi().mute(getId(), until)
    }

    public func unmute() -> Completable {
        return Fire.internalApi().unmute(getId())
    }

    public func mutedUntil() -> Date? {
        return Fire.internalApi().mutedUntil(getId())
    }

    public func muted() -> Bool {
        return Fire.internalApi().muted(getId())
    }

}
