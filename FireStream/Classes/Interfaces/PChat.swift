//
//  PChat.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

import RxSwift

/**
 * This interface is just provided for clarity
 */
public protocol PChat: PAbstractChat {

    /**
     * The unique chat id
     * @return id string
     */
    func getId() -> String

    /**
     * Remove the user from the chat's roster. It may be preferable to call
     * @see IFireStream#leaveChat(IChat)
     * @return completion
     */
    func leave() -> Completable

    /**
     * Get the chat name
     * @return name
     */
    func getName() -> String

    /**
     * Set the chat name.
     * @param name new name
     * @return completion
     */
    func setName(_ name: String) -> Completable

    /**
     * Get the group image url
     * @return image url
     */
    func getImageURL() -> String

    /**
     * Set the chat image url
     * @param url of group image
     * @return completion
     */
    func setImageURL(_ url: String) -> Completable

    /**
     * Get any custom data associated from the chat
     * @return custom data
     */
    func getCustomData() -> [String: Any]?

    /**
     * Associate custom data from the chat - you can add your own
     * data to a chat - topic, extra links etc...
     * @param data custom data to write
     * @return completion
     */
    func setCustomData(_ data: [String: Any]?) -> Completable

    /**
     * Get a list of members of the chat
     * @return list of users
     */
    func getUsers() -> [FireStreamUser]

    /**
     * Add users to a chat
     * @param sendInvite should an invitation message be sent?
     * @param users users to add, set the role of each user using user.setRoleType()
     * @return completion
     */
    func addUsers(_ sendInvite: Bool, _ users: FireStreamUser...) -> Completable

    /**
     * @see IChat#addUsers(Boolean, User...)
     */
    func addUsers(_ sendInvite: Bool, _ users: [FireStreamUser]) -> Completable

    /**
     * @see IChat#addUsers(Boolean, User...)
     */
    func addUser(_ sendInvite: Bool, _ user: FireStreamUser) -> Completable

    /**
     * Update users in chat
     * @param users users to update
     * @return completion
     */
    func updateUsers(_ users: FireStreamUser...) -> Completable

    /**
     * @see IChat#updateUsers(User...)
     */
    func updateUsers(_ users: [FireStreamUser]) -> Completable

    /**
     * @see IChat#updateUsers(User...)
     */
    func updateUser(_ user: FireStreamUser) -> Completable

    /**
     * Remove users from a chat
     * @param users users to remove
     * @return completion
     */
    func removeUsers(_ users: FireStreamUser...) -> Completable

    /**
     * @see IChat#removeUsers(User...)
     */
    func removeUsers(_ users: [FireStreamUser]) -> Completable

    /**
     * @see IChat#removeUsers(User...)
     */
    func removeUser(_ user: FireStreamUser?) -> Completable

    /**
     * Send an invite message to users
     * @param users to invite
     * @return completion
     */
    func inviteUsers(_ users: [FireStreamUser]) -> Completable

    /**
     * Set the role of a user
     * @param user to update
     * @param roleType new role type
     * @return completion
     */
    func setRole(_ user: FireStreamUser, _ roleType: RoleType) -> Completable

    /**
     * Get the users for a particular role
     * @param roleType to find
     * @return list of users
     */
    func getUsersForRoleType(_ roleType: RoleType) -> [FireStreamUser]

    /**
     * Get the role for a user
     * @param theUser to who's role to find
     * @return role
     */
    func getRoleType(_ theUser: FireStreamUser?) -> RoleType?

    /**
     * Get the role for the current user
     * @return role
     */
    func getMyRoleType() -> RoleType?

    /**
     * Get a list of roles that this user could be changed to. This will vary
     * depending on our own role level
     * @param user to test
     * @return list of roles
     */
    func getAvailableRoles(_ user: FireStreamUser) -> [RoleType]

    /**
     * Test to see if the current user has the required permission
     * @param required permission
     * @return true / false
     */
    func hasPermission(_ required: RoleType) -> Bool

    /**
     * Get an observable which is called when the name changes
     * @return observable
     */
    func getNameChangeEvents() -> Observable<String>

    /**
     * Get an observable which is called when the chat image changes
     * @return observable
     */
    func getImageURLChangeEvents() -> Observable<String>

    /**
     * Get an observable which is called when the custom data associated from the
     * chat is updated
     * @return observable
     */
    func getCustomDataChangedEvents() -> Observable<[String: Any]>

    /**
     * Get an observable which is called when the a user is added, removed or updated
     * @return observable
     */
    func getUserEvents() -> MultiQueueSubject<FireStreamEvent<FireStreamUser>>

    /**
     * Send a custom message
     * @param body custom message data
     * @param newId message's new ID before sending
     * @return completion
     */
    func sendMessageWithBody(_ body: [String: Any], _ newId: Consumer<String>?) -> Completable

    /**
     * Send a custom message
     * @param body custom message data
     * @return completion
     */
    func sendMessageWithBody(_ body: [String: Any]) -> Completable

    /**
     * Send a text message
     * @param text message text
     * @param newId message's new ID before sending
     * @return completion
     */
    func sendMessageWithText(_ text: String, _ newId: Consumer<String>?) -> Completable

    /**
     * Send a text message
     * @param text message text
     * @return completion
     */
    func sendMessageWithText(_ text: String) -> Completable

    /**
     * Send a typing indicator message
     * @param type typing state
     * @param newId message's new ID before sending
     * @return completion
     */
    func sendTypingIndicator(_ type: TypingStateType, _ newId: Consumer<String>?) -> Completable

    /**
     * Send a typing indicator message. An indicator should be sent when starting and stopping typing
     * @param type typing state
     * @return completion
     */
    func sendTypingIndicator(_ type: TypingStateType) -> Completable

    /**
     * Send a delivery receipt to a user. If delivery receipts are enabled,
     * a 'received' status will be returned as soon as a message is delivered
     * and then you can then manually send a 'read' status when the user
     * actually reads the message
     * @param type receipt type
     * @param newId message's new ID before sending
     * @return completion
     */
    func sendDeliveryReceipt(_ type: DeliveryReceiptType, _ messageId: String, _ newId: Consumer<String>?) -> Completable

    /**
     * Send a delivery receipt to a user. If delivery receipts are enabled,
     * a 'received' status will be returned as soon as a message is delivered
     * and then you can then manually send a 'read' status when the user
     * actually reads the message
     * @param type receipt type
     * @return completion
     */
    func sendDeliveryReceipt(_ type: DeliveryReceiptType, _ messageId: String) -> Completable

    /**
     * Send a custom sendable
     * @param sendable to send
     * @param newId message's new ID before sending
     * @return completion
     */
    func send(_ sendable: Sendable, _ newId: Consumer<String>?) -> Completable

    /**
     * Send a custom sendable
     * @param sendable to send
     * @return completion
     */
    func send(_ sendable: Sendable) -> Completable

    /**
     * Delete a sendable
     * @param sendable to delete
     * @return completion
     */
    func deleteSendable(_ sendable: Sendable) -> Completable

    /**
     * Mark a message as received
     * @param sendable to mark as received
     * @return completion
     */
    func markReceived(_ sendable: Sendable?) -> Completable

    /**
     * Mark a message as read
     * @param sendable to mark as read
     * @return completion
     */
    func markRead(_ sendable: Sendable?) -> Completable

}
