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
    public func accept(_ error: Error) throws {
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
        // MARK: TODO
        return Single.just(FireStreamEvent(.Added)).asObservable()
//        return Fire.privateApi().getFirebaseService().core.messagesOn(messagesPath(), newerThan, Fire.privateApi().getConfig().messageHistoryLimit).doOnNext(event -> {
//            Sendable sendable = event.get();
//            Sendable previous = getSendable(sendable.getId());
//            if (event.typeIs(EventType.Added)) {
//                sendables.add(sendable);
//            }
//            if (previous != null) {
//                if (event.typeIs(EventType.Modified)) {
//                    sendable.copyTo(previous);
//                }
//                if (event.typeIs(EventType.Removed)) {
//                    sendables.remove(previous);
//                }
//            }
//            getSendableEvents().getSendables().onNext(event);
//        }).doOnError(throwable -> {
//            events.publishThrowable().onNext(throwable);
//        }).subscribeOn(Schedulers.single()).observeOn(AndroidSchedulers.mainThread());
    }

    /**
     * Get a updateBatch of messages once
     * @param fromDate get messages from this date
     * @param toDate get messages until this date
     * @param limit limit the maximum number of messages
     * @return a events of errorMessage results
     */
    internal func loadMoreMessages(_ fromDate: Date?, _ toDate: Date?, _ limit: Int?) -> Single<[Sendable]> {
        // MARK: TODO
        return Single.just([])
//        return Fire.privateApi().getFirebaseService().core
//                .loadMoreMessages(messagesPath(), fromDate, toDate, limit)
//                .subscribeOn(Schedulers.single())
//                .observeOn(AndroidSchedulers.mainThread());
    }

    public func loadMoreMessages(_ fromDate: Date, _ toDate: Date) -> Single<[Sendable]> {
        return loadMoreMessages(fromDate, toDate, nil)
    }

    public func loadMoreMessagesFrom(_ fromDate: Date, _ limit: Int) -> Single<[Sendable]> {
        return loadMoreMessages(fromDate, nil, limit)
    }

    public func loadMoreMessagesTo(_ toDate: Date, _ limit: Int) -> Single<[Sendable]> {
        return loadMoreMessages(nil, toDate, limit);
    }

    public func loadMoreMessagesBefore(_ toDate: Date, _ limit: Int) -> Single<[Sendable]> {
        return Single.deferred {
            let before = Date(timeIntervalSince1970: toDate.timeIntervalSince1970 - 1)
            return self.loadMoreMessagesTo(before, limit)
        }
    }

    /**
     * This method gets the date of the last delivery receipt that we sent - i.e. the
     * last errorMessage WE received.
     * @return single date
     */
    internal func dateOfLastDeliveryReceipt() -> Single<Date> {
        // MARK: TODO
        return Single.just(Date())
//        return Fire.privateApi().getFirebaseService().core
//                .dateOfLastSentMessage(messagesPath())
//                .subscribeOn(Schedulers.single())
//                .observeOn(AndroidSchedulers.mainThread());
    }

    /**
     * Listen for changes in the value of a list reference
     * @param path to listen to
     * @return events of list events
     */
    internal func listChangeOn(path: Path) -> Observable<FireStreamEvent<ListData>> {
        // MARK: TODO
        return Single.just(FireStreamEvent(.Added)).asObservable()
//        return Fire.privateApi().getFirebaseService().core
//                .listChangeOn(path)
//                .subscribeOn(Schedulers.single())
//                .observeOn(AndroidSchedulers.mainThread());
    }

    public func send(messagesPath: Path, sendable: Sendable) -> Completable {
        return send(messagesPath: messagesPath, sendable: sendable, newId: nil)
    }

        /**
         * Send a errorMessage to a messages ref
         * @param messagesPath
         * @param sendable item to be sent
         * @param newId the ID of the new errorMessage
         * @return single containing errorMessage id
         */
    public func send(messagesPath: Path, sendable: Sendable, newId: Consumer<String>?) -> Completable {
        // MARK: TODO
        return Completable.empty()
//        return Fire.privateApi().getFirebaseService().core
//                .send(messagesPath, sendable, newId)
//                .subscribeOn(Schedulers.single())
//                .observeOn(AndroidSchedulers.mainThread());
    }

    /**
     * Delete a sendable from our queue
     * @param messagesPath
     * @return completion
     */
    internal func deleteSendable(messagesPath: Path) -> Completable {
        // MARK: TODO
        return Completable.empty()
//        return Fire.privateApi().getFirebaseService().core
//                .deleteSendable(messagesPath)
//                .subscribeOn(Schedulers.single())
//                .observeOn(AndroidSchedulers.mainThread());
    }

    /**
     * Remove a user from a reference
     * @param path for users
     * @param user to remove
     * @return completion
     */
    internal func removeUser(path: Path, user: User) -> Completable {
        return removeUsers(path: path, users: user)
    }

    /**
     * Remove users from a reference
     * @param path for users
     * @param users to remove
     * @return completion
     */
    internal func removeUsers(path: Path, users: User...) -> Completable {
        return removeUsers(path: path, users: users)
    }

    /**
     * Remove users from a reference
     * @param path for users
     * @param users to remove
     * @return completion
     */
    internal func removeUsers(path: Path, users: [User]) -> Completable {
        // MARK: TODO
        return Completable.empty()
//        return Fire.privateApi().getFirebaseService().core
//                .removeUsers(path, users)
//                .subscribeOn(Schedulers.single())
//                .observeOn(AndroidSchedulers.mainThread());
    }

    /**
     * Add a user to a reference
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param user to add
     * @return completion
     */
    internal func addUser(path: Path, dataProvider: User.DataProvider, user: User) -> Completable {
        return addUsers(path: path, dataProvider: dataProvider, users: user)
    }

    /**
     * Add users to a reference
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param users to add
     * @return completion
     */
    public func addUsers(path: Path, dataProvider: User.DataProvider, users: User...) -> Completable {
        return addUsers(path: path, dataProvider: dataProvider, users: users)
    }

    /**
     * Add users to a reference
     * @param path
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param users to add
     * @return completion
     */
    public func addUsers(path: Path, dataProvider: User.DataProvider, users: [User]) -> Completable {
        // MARK: TODO
        return Completable.empty()
//        return Fire.privateApi().getFirebaseService().core
//                .addUsers(path, dataProvider, users)
//                .subscribeOn(Schedulers.single())
//                .observeOn(AndroidSchedulers.mainThread());
    }

    /**
     * Updates a user for a reference
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param user to update
     * @return completion
     */
    public func updateUser(path: Path, dataProvider: User.DataProvider, user: User) -> Completable {
        return updateUsers(path: path, dataProvider: dataProvider, users: user)
    }

    /**
     * Update users for a reference
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param users to update
     * @return completion
     */
    public func updateUsers(path: Path, dataProvider: User.DataProvider, users: User...) -> Completable {
        return updateUsers(path: path, dataProvider: dataProvider, users: users)
    }

    /**
     * Update users for a reference
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param users to update
     * @return completion
     */
    public func updateUsers(path: Path, dataProvider: User.DataProvider, users: [User]) -> Completable {
        // MARK: TODO
        return Completable.empty()
//        return Fire.privateApi().getFirebaseService().core
//                .updateUsers(path, dataProvider, users)
//                .subscribeOn(Schedulers.single())
//                .observeOn(AndroidSchedulers.mainThread());
    }

    public func connect() throws {
        self.dm.add(dateOfLastDeliveryReceipt()
            .asObservable()
            .flatMap({ self.messagesOn($0) })
//            .subscribeOn(Schedulers.single())
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

        debug("Sendable: \(sendable.getType() ) \(sendable.getId()), date: \(sendable.getDate()?.timeIntervalSince1970)")

        // In general, we are mostly interested when messages are added
        if (sendable.isType(SendableType.message())) {
            events.getMessages().onNext(event.to(sendable.toMessage()))
        }
        if (sendable.isType(SendableType.deliveryReceipt())) {
            events.getDeliveryReceipts().onNext(event.to(sendable.toDeliveryReceipt()))
        }
        if (sendable.isType(SendableType.typingState())) {
            events.getTypingStates().onNext(event.to(sendable.toTypingState()))
        }
        if (sendable.isType(SendableType.invitation())) {
            events.getInvitations().onNext(event.to(sendable.toInvitation()))
        }
        if (sendable.isType(SendableType.presence())) {
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
        for sendable in self.sendables {
            if (sendable.getId() == id) {
                return sendable
            }
        }
        return nil
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
    internal func messagesPath() throws -> Path {
        throw FireStreamError("messagesPath() not implemented")
    }

    public func getDisposableMap() -> DisposableMap {
        return self.dm
    }

    public func manage(_ disposable: Disposable) {
        getDisposableMap().add(disposable)
    }

    public func markRead(message: Sendable) throws -> Completable {
        throw FireStreamError("markRead() not implemented")
    }

    public func markReceived(message: Sendable) throws -> Completable {
        throw FireStreamError("markReceived() not implemented")
    }

    public func debug(_ text: String) {
        // MARK: TODO
        // if (Fire.privateApi().getConfig().debugEnabled) {
            print(text)
        // }
    }

}
