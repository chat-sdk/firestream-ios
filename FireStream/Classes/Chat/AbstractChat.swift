//
//  AbstractChat.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

import Foundation
import RxSwift

/**
* This class handles common elements of a conversation bit it 1-to-1 or group.
* Mainly sending and receiving messages.
*/
public class AbstractChat: PAbstractChat {

    /**
     * Store the disposables so we can dispose of all of them when the user logs out
     */
    internal var dm: DisposableMap

    /**
     * Event events
     */
    internal var events: Events

    /**
     * A list of all sendables received
     */
    internal var sendables: [Sendable]

    internal init() {
        self.dm = DisposableMap()
        self.events = Events()
        self.sendables = [Sendable]()
    }

    /**
     * Error handler method so we can redirect all errors to the error events
     * @param throwable - the events error
     * @throws Exception
     */
    public func accept(_ error: Error) {
        self.events.errors.onError(error)
    }

    /**
     * Start listening to the current errorMessage reference and retrieve all messages
     * @return a events of errorMessage results
     */
    internal func messagesOn() -> Observable<FireStreamEvent<Sendable>> {
        return messagesOn(nil)
    }

    /**
     * Start listening to the current errorMessage reference and pass the messages to the events
     * @param newerThan only listen for messages after this date
     * @return a events of errorMessage results
     */
    internal func messagesOn(_ newerThan: Date?) -> Observable<FireStreamEvent<Sendable>> {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Observable.error(Fire.internalApi().getFirebaseServiceNilError())
        }

        guard let config = Fire.internalApi().getConfig() else {
            return Observable.error(Fire.internalApi().getConfigNilError())
        }

        guard let messagesPath = messagesPath() else {
            return Observable.error(FireStreamError("messagesPath is nil"))
        }

        return firebaseService.core.messagesOn(messagesPath, newerThan, config.messageHistoryLimit)
            .do(onNext: { event in
                guard let sendable = event.get() else {
                    return
                }

                guard let sid = sendable.getId() else {
                    return
                }

                if event.typeIs(EventType.Added) {
                    self.sendables.append(sendable)
                }

                if let previous = self.getSendable(sid) {
                    if event.typeIs(EventType.Modified) {
                        sendable.copyTo(previous)
                    }
                    if event.typeIs(EventType.Removed) {
                        self.sendables.removeAll(where: { $0.id == previous.id })
                    }
                }
                self.getSendableEvents().getSendables().onNext(event)
            }, onError: { error in
                self.events.publishThrowable().onNext(error)
            })
    }

    /**
     * Get a updateBatch of messages once
     * @param fromDate get messages from this date
     * @param toDate get messages until this date
     * @param limit limit the maximum number of messages
     * @return a events of errorMessage results
     */
    internal func loadMoreMessages(_ fromDate: Date?, _ toDate: Date?, _ limit: Int?) -> Single<[Sendable]> {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Single.error(Fire.internalApi().getFirebaseServiceNilError())
        }

        guard let messagesPath = messagesPath() else {
            return Single.error(FireStreamError("messagesPath is nil"))
        }

        return firebaseService.core.loadMoreMessages(messagesPath, fromDate, toDate, limit)
            .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
            .observeOn(MainScheduler.instance)
    }

    public func loadMoreMessages(_ fromDate: Date, _ toDate: Date) -> Single<[Sendable]> {
        return loadMoreMessages(fromDate, toDate, nil)
    }

    public func loadMoreMessagesFrom(_ fromDate: Date, _ limit: Int) -> Single<[Sendable]> {
        return loadMoreMessages(fromDate, nil, limit)
    }

    public func loadMoreMessagesTo(_ toDate: Date, _ limit: Int) -> Single<[Sendable]> {
        return loadMoreMessages(nil, toDate, limit)
    }

    public func loadMoreMessagesBefore(_ toDate: Date, _ limit: Int) -> Single<[Sendable]> {
        return Single.deferred {
            let before = Date(timestamp: toDate.timestamp - 1)
            return self.loadMoreMessagesTo(before, limit)
        }
    }

    /**
     * This method gets the date of the last delivery receipt that we sent - i.e. the
     * last errorMessage WE received.
     * @return single date
     */
    internal func dateOfLastDeliveryReceipt() -> Single<Date> {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Single.error(Fire.internalApi().getFirebaseServiceNilError())
        }

        guard let messagesPath = messagesPath() else {
            return Single.error(FireStreamError("messagesPath is nil"))
        }

        return firebaseService.core.dateOfLastSentMessage(messagesPath)
    }

    /**
     * Listen for changes in the value of a list reference
     * @param path to listen to
     * @return events of list events
     */
    internal func listChangeOn(_ path: Path?) -> Observable<FireStreamEvent<ListData>> {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Observable.error(Fire.internalApi().getFirebaseServiceNilError())
        }
        guard let path = path else {
            return Observable.error(FireStreamError("path is nil"))
        }
        return firebaseService.core.listChangeOn(path)
                .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
                .observeOn(MainScheduler.instance)
    }

    public func send(_ messagesPath: Path?, _ sendable: Sendable) -> Completable {
        return send(messagesPath, sendable, nil)
    }

    /**
     * Send a errorMessage to a messages ref
     * @param messagesPath
     * @param sendable item to be sent
     * @param newId the ID of the new errorMessage
     * @return single containing errorMessage id
     */
    public func send(_ messagesPath: Path?, _ sendable: Sendable, _ newId: Consumer<String>?) -> Completable {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Completable.error(Fire.internalApi().getFirebaseServiceNilError())
        }
        guard let messagesPath = messagesPath else {
            return Completable.error(FireStreamError("messagesPath is nil"))
        }
        return firebaseService.core.send(messagesPath, sendable, newId)
                .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
                .observeOn(MainScheduler.instance)
    }

    /**
     * Delete a sendable from our queue
     * @param messagesPath
     * @return completion
     */
    internal func deleteSendable(_ messagesPath: Path?) -> Completable {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Completable.error(Fire.internalApi().getFirebaseServiceNilError())
        }
        guard let messagesPath = messagesPath else {
            return Completable.error(FireStreamError("messagesPath is nil"))
        }
        return firebaseService.core.deleteSendable(messagesPath)
                .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
                .observeOn(MainScheduler.instance)
    }

    /**
     * Remove a user from a reference
     * @param path for users
     * @param user to remove
     * @return completion
     */
    internal func removeUser(_ path: Path?, _ user: FireStreamUser?) -> Completable {
        if let user = user {
            return removeUsers(path, user)
        }
        return removeUsers(path, [])
    }

    /**
     * Remove users from a reference
     * @param path for users
     * @param users to remove
     * @return completion
     */
    internal func removeUsers(_ path: Path?, _ users: FireStreamUser...) -> Completable {
        return removeUsers(path, users)
    }

    /**
     * Remove users from a reference
     * @param path for users
     * @param users to remove
     * @return completion
     */
    internal func removeUsers(_ path: Path?, _ users: [FireStreamUser]) -> Completable {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Completable.error(Fire.internalApi().getFirebaseServiceNilError())
        }
        guard let path = path else {
            return Completable.error(FireStreamError("path is nil"))
        }
        return firebaseService.core.removeUsers(path, users)
                .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
                .observeOn(MainScheduler.instance)
    }

    /**
     * Add a user to a reference
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param user to add
     * @return completion
     */
    internal func addUser(_ path: Path?, _ dataProvider: FireStreamUser.DataProvider, _ user: FireStreamUser) -> Completable {
        return addUsers(path, dataProvider, user)
    }

    /**
     * Add users to a reference
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param users to add
     * @return completion
     */
    public func addUsers(_ path: Path?, _ dataProvider: FireStreamUser.DataProvider, _ users: FireStreamUser...) -> Completable {
        return addUsers(path, dataProvider, users)
    }

    /**
     * Add users to a reference
     * @param path
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param users to add
     * @return completion
     */
    public func addUsers(_ path: Path?, _ dataProvider: FireStreamUser.DataProvider, _ users: [FireStreamUser]) -> Completable {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Completable.error(Fire.internalApi().getFirebaseServiceNilError())
        }
        guard let path = path else {
            return Completable.error(FireStreamError("path is nil"))
        }
        return firebaseService.core.addUsers(path, dataProvider, users)
            .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
            .observeOn(MainScheduler.instance)
    }

    /**
     * Updates a user for a reference
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param user to update
     * @return completion
     */
    public func updateUser(_ path: Path?, _ dataProvider: FireStreamUser.DataProvider, _ user: FireStreamUser) -> Completable {
        return updateUsers(path, dataProvider, user)
    }

    /**
     * Update users for a reference
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param users to update
     * @return completion
     */
    public func updateUsers(_ path: Path?, _ dataProvider: FireStreamUser.DataProvider, _ users: FireStreamUser...) -> Completable {
        return updateUsers(path, dataProvider, users)
    }

    /**
     * Update users for a reference
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param users to update
     * @return completion
     */
    public func updateUsers(_ path: Path?, _ dataProvider: FireStreamUser.DataProvider, _ users: [FireStreamUser]) -> Completable {
        guard let firebaseService = Fire.internalApi().getFirebaseService() else {
            return Completable.error(Fire.internalApi().getFirebaseServiceNilError())
        }
        guard let path = path else {
            return Completable.error(FireStreamError("path is nil"))
        }
        return firebaseService.core.updateUsers(path, dataProvider, users)
            .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
            .observeOn(MainScheduler.instance)
    }

    public func connect() throws {
        self.dm.add(dateOfLastDeliveryReceipt()
            .asObservable()
            .flatMap({ self.messagesOn($0) })
            .subscribeOn(SerialDispatchQueueScheduler.init(qos: .background))
            .subscribe(onNext: passMessageResultToStream(event:)))
    }

    public func disconnect() {
        self.dm.dispose()
    }

    /**
     * Convenience method to cast sendables and send them to the correct events
     * @param event sendable event
     */
    internal func passMessageResultToStream(event: FireStreamEvent<Sendable>) {
        guard let sendable = event.get() else {
            return
        }

        debug("Sendable: \(sendable.getType() ) \(sendable.getId()), date: \(sendable.getDate()?.timestamp)")

        // In general, we are mostly interested when messages are added
        if sendable.isType(SendableType.message()) {
            events.getMessages().onNext(event.to(sendable.toMessage()))
        }
        if sendable.isType(SendableType.deliveryReceipt()) {
            events.getDeliveryReceipts().onNext(event.to(sendable.toDeliveryReceipt()))
        }
        if sendable.isType(SendableType.typingState()) {
            events.getTypingStates().onNext(event.to(sendable.toTypingState()))
        }
        if sendable.isType(SendableType.invitation()) {
            events.getInvitations().onNext(event.to(sendable.toInvitation()))
        }
        if sendable.isType(SendableType.presence()) {
            events.getPresences().onNext(event.to(sendable.toPresence()))
        }
    }

    public func getSendables() -> [Sendable] {
        return self.sendables
    }

    public func getSendables(_ type: SendableType) -> [Sendable] {
        return self.sendables.filter { $0.isType(type) }
    }

    public func getSendable(_ id: String) -> Sendable? {
        return sendables.first { $0.id == id }
    }

    /**
     * returns the events object which exposes the different sendable streams
     * @return events
     */
    public func getSendableEvents() -> Events {
        return self.events
    }

    /**
     * Overridable messages reference
     * @return Firestore messages reference
     */
    internal func messagesPath() -> Path? {
        return nil
    }

    public func getDisposableMap() -> DisposableMap {
        return self.dm
    }

    public func manage(_ disposable: Disposable) {
        getDisposableMap().add(disposable)
    }

    public func markRead(_ sendable: Sendable) -> Completable {
        return Completable.error(FireStreamError("markRead() not implemented"))
    }

    public func markReceived(_ sendable: Sendable) -> Completable {
        return Completable.error(FireStreamError("markReceived() not implemented"))
    }

    public func debug(_ text: String) {
        guard let config = Fire.internalApi().getConfig() else {
            return
        }
//        if config.debugEnabledPredicate<FireStreamEvent<Sendable>> {
            print(text)
//        }
    }

    internal func deliveryReceiptFilter() -> Predicate<FireStreamEvent<Message>> {
        var filters: [Predicate<FireStreamEvent<Message>>] = [Filter.notFromMe(), Filter.byEventType(EventType.Added)]
        if let markReceivedFilter = Fire.internalApi().getMarkReceivedFilter() {
            filters.insert(markReceivedFilter, at: 0)
        }
        return Filter.and(filters)
    }

}
