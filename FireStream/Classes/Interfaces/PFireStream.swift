//
//  PFireStream.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

import RxSwift

public struct Chat {}

public protocol PFireStream: PAbstractChat {

    func initialize(config: Config?)
    func initialize()
    func isInitialized() -> Bool

    /**
     * @return authenticated user
     */
    func currentUser() -> User

    /**
     * @return id of authenticated user
     */
    func currentUserId() -> String

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
    func sendDeliveryReceipt(userId: String, type: DeliveryReceiptType, messageId: String) -> Completable
    func sendDeliveryReceipt(userId: String, type: DeliveryReceiptType, messageId: String, newId: Consumer<String>?) -> Completable

    func sendInvitation(userId: String, type: InvitationType, id: String) -> Completable
    func sendInvitation(userId: String, type: InvitationType, groupId: String, newId: Consumer<String>?) -> Completable

    func send(toUserId: String, sendable: Sendable) -> Completable
    func send(toUserId: String, sendable: Sendable, newId: Consumer<String>?) -> Completable

    func deleteSendable (sendable: Sendable) -> Completable
    func sendPresence(userId: String, type: PresenceType) -> Completable
    func sendPresence(userId: String, type: PresenceType, newId: Consumer<String>?) -> Completable

    func sendMessageWithText(userId: String, text: String) -> Completable
    func sendMessageWithText(userId: String, text: String, newId: Consumer<String>?) -> Completable

    func sendMessageWithBody(userId: String, body: [String: Any]) -> Completable
    func sendMessageWithBody(userId: String, body: [String: Any], newId: Consumer<String>?) -> Completable

    /**
     * Send a typing indicator update to a user. This should be sent when the user
     * starts or stops typing
     * @param userId - the recipient user id
     * @param type - the status getTypingStateType
     * @return - subscribe to get a completion, error update from the method
     */
    func sendTypingIndicator(userId: String, type: TypingStateType) -> Completable
    func sendTypingIndicator(userId: String, type: TypingStateType, newId: Consumer<String>?) -> Completable

    // Blocked

    func block(user: User) -> Completable
    func unblock(user: User) -> Completable
    func getBlocked() -> [User]
    func isBlocked(user: User) -> Bool

    // Contacts

    func addContact(user: User, type: ContactType) -> Completable
    func removeContact(user: User) -> Completable
    func getContacts() -> [User]

    // Chats

    func createChat(name: String?, imageURL: String?, users: User...) -> Single<Chat>
    func createChat(name: String?, imageURL: String?, customData: [String: Any]?, users: User...) -> Single<Chat>
    func createChat(name: String?, imageURL: String?, users: [User]) -> Single<Chat>
    func createChat(name: String?, imageURL: String?, customData: [String: Any]?, users: [User]) -> Single<Chat>

    /**
     * Leave the chat. When you leave, you will be removed from the
     * chat's roster
     * @param chat to leave
     * @return completion
     */
    func leaveChat(chat: PChat) -> Completable

    /**
     * Join the chat. To join you must already be in the chat roster
     * @param chat to join
     * @return completion
     */
    func joinChat(chat: PChat) -> Completable

    func getChat(chatId: String) -> PChat
    func getChats() -> [PChat]

    // Events

    func getChatEvents() -> MultiQueueSubject<FireStreamEvent<Chat>>
    func getBlockedEvents() -> MultiQueueSubject<FireStreamEvent<User>>
    func getContactEvents() -> MultiQueueSubject<FireStreamEvent<User>>
    func getConnectionEvents() -> Observable<ConnectionEvent>

}
