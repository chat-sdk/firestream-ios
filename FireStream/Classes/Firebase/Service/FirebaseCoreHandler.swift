//
//  FirebaseCoreHandler.swift
//  FireStream
//
//  Created by Pepe Becker on 2/4/20.
//

import RxSwift

public class FirebaseCoreHandler {

    /**
     * Listen for changes in the value of a list reference
     *
     * @param path to listen to
     * @return events of list events
     */
    public func listChangeOn(_ path: Path) -> Observable<FireStreamEvent<ListData>> {
        return Observable.empty()
    }

    /**
     * Delete a sendable from our queue
     *
     * @param messagesPath
     * @return completion
     */
    public func deleteSendable(_ messagesPath: Path) -> Completable {
        return Completable.empty()
    }

    /**
     * Send a message to a messages ref
     *
     * @param messagesPath Firestore reference for message collection
     * @param sendable item to be sent
     * @param newId get the id of the new message before it's sent
     * @return completion
     */
    public func send(_ messagesPath: Path, _ sendable: Sendable, _ newId: Consumer<String>?) -> Completable {
       return Completable.empty()
    }

    /**
     * Add users to a reference
     *
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param users        to add
     * @return completion
     */
    public func addUsers(_ path: Path, _ dataProvider: FireStreamUser.DataProvider, _ users: [FireStreamUser]) -> Completable {
       return Completable.empty()
    }

    /**
     * Remove users from a reference
     *
     * @param path  for users
     * @param users to remove
     * @return completion
     */
    public func removeUsers(_ path: Path, _ users: [FireStreamUser]) -> Completable {
       return Completable.empty()
    }

    /**
     * Update users for a reference
     * @param path for users
     * @param dataProvider a callback to extract the data to add from the user
     *                     this allows us to use one method to write to multiple different places
     * @param users to update
     * @return completion
     */
    public func updateUsers(_ path: Path, _ dataProvider: FireStreamUser.DataProvider, _ users: [FireStreamUser]) -> Completable {
       return Completable.empty()
    }

    /**
     * Get a updateBatch of messages once
     * @param messagesPath
     * @param fromDate get messages from this date
     * @param toDate get messages until this date
     * @param limit limit the maximum number of messages
     * @return a events of message results
     */
    public func loadMoreMessages(_ messagesPath: Path, _ fromDate: Date?, _ toDate: Date?, _ limit: Int?) -> Single<[Sendable]> {
       return Single.just([])
    }

    /**
     * This method gets the date of the last delivery receipt that we sent - i.e. the
     * last message WE received.
     * @param messagesPath
     * @return single date
     */
    public func dateOfLastSentMessage(_ messagesPath: Path) -> Single<Date> {
       return Single.just(Date())
    }

    /**
     * Start listening to the current message reference and pass the messages to the events
     * @param messagesPath
     * @param newerThan only listen for messages after this date
     * @param limit limit the maximum number of historic messages
     * @return a events of message results
     */
    public func messagesOn(_ messagesPath: Path, _ newerThan: Date?, _ limit: Int?) -> Observable<FireStreamEvent<Sendable>> {
        return Single.just(FireStreamEvent(.Added)).asObservable()
    }

    /**
     * Return a Firebase timestamp object
     * @return appropriate server timestamp object
     */
    public func timestamp() -> Any {
        return -1
    }

    public func mute(_ path: Path, _ data: [String: Any]) -> Completable {
        return Completable.empty()
    }

    public func unmute(_ path: Path) -> Completable {
        return Completable.empty()
    }

}
