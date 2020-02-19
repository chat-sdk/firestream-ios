//
//  PFireStream.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

import RxSwift

public protocol PFireStream: PAbstractChat {

    func initialize(_ config: Config?)
    func initialize()
    func isInitialized() -> Bool

    /**
     * @return authenticated user
     */
    func currentUser() -> FireStreamUser?

    /**
     * @return id of authenticated user
     */
    func currentUserId() -> String?

    // Messages

    /**
     * Send a delivery receipt to a user. If delivery receipts are enabled,
     * a 'received' status will be returned as soon as a errorMessage isType delivered
     * and then you can then manually send a 'read' status when the user
     * actually reads the errorMessage
     * @param userId - the recipient user id
     * @param type - the status getTypingStateType
     * @return - subscribe to get a completion, error update from the method
     */
    func sendDeliveryReceipt(_ userId: String?, _ type: DeliveryReceiptType?, _ messageId: String?) -> Completable
    func sendDeliveryReceipt(_ userId: String?, _ type: DeliveryReceiptType?, _ messageId: String?, _ newId: Consumer<String>?) -> Completable

    func sendInvitation(_ userId: String, _ type: InvitationType, _ id: String) -> Completable
    func sendInvitation(_ userId: String, _ type: InvitationType, _ groupId: String, _ newId: Consumer<String>?) -> Completable

    func send(_ toUserId: String, _ sendable: Sendable) -> Completable
    func send(_ toUserId: String, _ sendable: Sendable, _ newId: Consumer<String>?) -> Completable

    func deleteSendable(_ sendable: Sendable?) -> Completable
    func sendPresence(_ userId: String, _ type: PresenceType) -> Completable
    func sendPresence(_ userId: String, _ type: PresenceType, _ newId: Consumer<String>?) -> Completable

    func sendMessageWithText(_ userId: String, _ text: String) -> Completable
    func sendMessageWithText(_ userId: String, _ text: String, _ newId: Consumer<String>?) -> Completable

    func sendMessageWithBody(_ userId: String, _ body: [String: Any]) -> Completable
    func sendMessageWithBody(_ userId: String, _ body: [String: Any], _ newId: Consumer<String>?) -> Completable

    /**
     * Send a typing indicator update to a user. This should be sent when the user
     * starts or stops typing
     * @param userId - the recipient user id
     * @param type - the status getTypingStateType
     * @return - subscribe to get a completion, error update from the method
     */
    func sendTypingIndicator(_ userId: String, _ type: TypingStateType) -> Completable
    func sendTypingIndicator(_ userId: String, _ type: TypingStateType, _ newId: Consumer<String>?) -> Completable

    // Blocked

    func block(_ user: FireStreamUser) -> Completable
    func unblock(_ user: FireStreamUser) -> Completable
    func getBlocked() -> [FireStreamUser]
    func isBlocked(_ user: FireStreamUser) -> Bool

    // Contacts

    func addContact(_ user: FireStreamUser, _ type: ContactType) -> Completable
    func removeContact(_ user: FireStreamUser) -> Completable
    func getContacts() -> [FireStreamUser]

    // Chats

    func createChat(_ name: String?, _ imageURL: String?, _ users: FireStreamUser...) -> Single<Chat>
    func createChat(_ name: String?, _ imageURL: String?, _ customData: [String: Any]?, _ users: FireStreamUser...) -> Single<Chat>
    func createChat(_ name: String?, _ imageURL: String?, _ users: [FireStreamUser]) -> Single<Chat>
    func createChat(_ name: String?, _ imageURL: String?, _ customData: [String: Any]?, _ users: [FireStreamUser]) -> Single<Chat>

    /**
     * Leave the chat. When you leave, you will be removed from the
     * chat's roster
     * @param chat to leave
     * @return completion
     */
    func leaveChat(_ chat: PChat) -> Completable

    /**
     * Join the chat. To join you must already be in the chat roster
     * @param chat to join
     * @return completion
     */
    func joinChat(_ chat: PChat) -> Completable

    func getChat(_ chatId: String) -> PChat?
    func getChats() -> [PChat]

    // Events

    func getChatEvents() -> MultiQueueSubject<FireStreamEvent<Chat>>
    func getBlockedEvents() -> MultiQueueSubject<FireStreamEvent<FireStreamUser>>
    func getContactEvents() -> MultiQueueSubject<FireStreamEvent<FireStreamUser>>
    func getConnectionEvents() -> Observable<ConnectionEvent>

}
