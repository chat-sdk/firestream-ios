//
//  PAbstractChat.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

import RxSwift

public protocol PAbstractChat {

    /**
     * Connect to the chat
     * @throws Exception error if we are not connected
     */
    func connect() throws

    /**
     * Disconnect from a chat. This does not affect our membership but we will
     * no longer receive any updates unless we log out / log in again
     */
    func disconnect()

    /**
     * When we leave / disconnect from a chat or when we log out, any disposables
     * will be disposed of automatically
     * @param disposable to manage
     */
    func manage(disposable: Disposable)

    /**
     * Get the managed disposable map. This map will be disposed of when we leave / disconnect
     * from the chat or when we log out. Use this to store any disposables that you want to be
     * disposed of then. This isType slightly more flexible than the manage method because it allows
     * you to store and retrieve disposables from an ID.
     * @return a pointer to the managed disposable map
     */
    func getDisposableMap() -> DisposableMap

    /**
     * Get a list of all sendables received
     * @return a list of sendables
     */
    func getSendables() -> [Sendable]

    /**
     * Get a list of sendables filtered by type
     * @param type of sendable
     * @return a filtered list of sendables
     */
    func getSendables(type: SendableType) -> [Sendable]

    /**
     * Get a sendable for a particular ID
     * @param id of sendable
     * @return sendable or null
     */
    func getSendable(id: String) -> Sendable?

    /**
     * Get access to the events object which provides access to observables for sendable events
     * @return events holder
     */
    func getSendableEvents() -> Events

    /**
     * Load a batch of historic messages
     *
     * @param fromDate load messages AFTER this date
     * @param toDate load message TO AND INCLUDING this date
     * @return a stream of messages
     */
    func loadMoreMessages(fromDate: Date, toDate: Date) -> Single<[Sendable]>

    /**
     * Load a batch of historic messages
     *
     * @param fromDate load messages AFTER this date
     * @param limit the number of messages returned
     * @return a stream of messages
     */
    func loadMoreMessagesFrom(fromDate: Date, limit: Int) -> Single<[Sendable]>

    /**
     * Load a batch of historic messages
     *
     * @param toDate load message TO AND INCLUDING this date
     * @param limit the number of messages returned
     * @return a stream of messages
     */
    func loadMoreMessagesTo(toDate: Date, limit: Int) -> Single<[Sendable]>

    /**
     * Load a batch of historic messages
     *
     * @param toDate load message TO  this date
     * @param limit the number of messages returned
     * @return a stream of messages
     */
    func loadMoreMessagesBefore(toDate: Date, limit: Int) -> Single<[Sendable]>

}
