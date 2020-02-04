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
    func setName(name: String) -> Completable

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
    func setImageURL(url: String) -> Completable

    /**
     * Get any custom data associated from the chat
     * @return custom data
     */
    func getCustomData() -> [String: Any]

    /**
     * Associate custom data from the chat - you can add your own
     * data to a chat - topic, extra links etc...
     * @param data custom data to write
     * @return completion
     */
    func setCustomData(data: [String: Any]) -> Completable

    /**
     * Get a list of members of the chat
     * @return list of users
     */
    func getUsers() -> [User]

    /**
     * Get a list of users from the FireStreamUser namespace
     * These are exactly the same users but may be useful if
     * your project already has a User class to avoid a clash
     * @return list of FireStreamUsers
     */
    func getFireStreamUsers() -> [FireStreamUser]

    /**
     * Add users to a chat
     * @param sendInvite should an invitation message be sent?
     * @param users users to add, set the role of each user using user.setRoleType()
     * @return completion
     */
    func addUsers(sendInvite: Bool, users: User...) -> Completable

    /**
     * @see IChat#addUsers(Boolean, User...)
     */
    func addUsers(sendInvite: Bool, users: [User]) -> Completable

    /**
     * @see IChat#addUsers(Boolean, User...)
     */
    func addUser(sendInvite: Bool, user: User) -> Completable

    /**
     * Update users in chat
     * @param users users to update
     * @return completion
     */
    func updateUsers(users: User...) -> Completable

    /**
     * @see IChat#updateUsers(User...)
     */
    func updateUsers(users: [User]) -> Completable

    /**
     * @see IChat#updateUsers(User...)
     */
    func updateUser(user: User) -> Completable

    /**
     * Remove users from a chat
     * @param users users to remove
     * @return completion
     */
    func removeUsers(users: User...) -> Completable

    /**
     * @see IChat#removeUsers(User...)
     */
    func removeUsers(users: [User]) -> Completable

    /**
     * @see IChat#removeUsers(User...)
     */
    func removeUser(user: User) -> Completable

    /**
     * Send an invite message to users
     * @param users to invite
     * @return completion
     */
    func inviteUsers(users: [User]) -> Completable

    /**
     * Set the role of a user
     * @param user to update
     * @param roleType new role type
     * @return completion
     */
    func setRole(user: User, roleType: RoleType) -> Completable

    /**
     * Get the users for a particular role
     * @param roleType to find
     * @return list of users
     */
    func getUsersForRoleType(roleType: RoleType) -> [User]

    /**
     * Get the role for a user
     * @param theUser to who's role to find
     * @return role
     */
    func getRoleType(theUser: User) -> RoleType

    /**
     * Get the role for the current user
     * @return role
     */
    func getMyRoleType() -> RoleType

    /**
     * Get a list of roles that this user could be changed to. This will vary
     * depending on our own role level
     * @param user to test
     * @return list of roles
     */
    func getAvailableRoles(user: User) -> [RoleType]

    /**
     * Test to see if the current user has the required permission
     * @param required permission
     * @return true / false
     */
    func hasPermission(required: RoleType) -> Bool

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
    func getUserEvents() -> MultiQueueSubject<FireStreamEvent<User>>

    /**
     * Send a custom message
     * @param body custom message data
     * @param newId message's new ID before sending
     * @return completion
     */
    func sendMessageWithBody(body: [String: Any], newId: Consumer<String>?) -> Completable

    /**
     * Send a custom message
     * @param body custom message data
     * @return completion
     */
    func sendMessageWithBody(body: [String: Any]) -> Completable

    /**
     * Send a text message
     * @param text message text
     * @param newId message's new ID before sending
     * @return completion
     */
    func sendMessageWithText(text: String, newId: Consumer<String>?) -> Completable

    /**
     * Send a text message
     * @param text message text
     * @return completion
     */
    func sendMessageWithText(text: String) -> Completable

    /**
     * Send a typing indicator message
     * @param type typing state
     * @param newId message's new ID before sending
     * @return completion
     */
    func sendTypingIndicator(type: TypingStateType, newId: Consumer<String>?) -> Completable

    /**
     * Send a typing indicator message. An indicator should be sent when starting and stopping typing
     * @param type typing state
     * @return completion
     */
    func sendTypingIndicator(type: TypingStateType) -> Completable

    /**
     * Send a delivery receipt to a user. If delivery receipts are enabled,
     * a 'received' status will be returned as soon as a message is delivered
     * and then you can then manually send a 'read' status when the user
     * actually reads the message
     * @param type receipt type
     * @param newId message's new ID before sending
     * @return completion
     */
    func sendDeliveryReceipt(type: DeliveryReceiptType, messageId: String, newId: Consumer<String>?) -> Completable

    /**
     * Send a delivery receipt to a user. If delivery receipts are enabled,
     * a 'received' status will be returned as soon as a message is delivered
     * and then you can then manually send a 'read' status when the user
     * actually reads the message
     * @param type receipt type
     * @return completion
     */
    func sendDeliveryReceipt(type: DeliveryReceiptType, messageId: String) -> Completable

    /**
     * Send a custom sendable
     * @param sendable to send
     * @param newId message's new ID before sending
     * @return completion
     */
    func send(sendable: Sendable, newId: Consumer<String>?) -> Completable

    /**
     * Send a custom sendable
     * @param sendable to send
     * @return completion
     */
    func send(sendable: Sendable) -> Completable

    /**
     * Delete a sendable
     * @param sendable to delete
     * @return completion
     */
    func deleteSendable(sendable: Sendable) -> Completable

    /**
     * Mark a message as received
     * @param sendable to mark as received
     * @return completion
     */
    func markReceived(sendable: Sendable) -> Completable

    /**
     * Mark a message as read
     * @param sendable to mark as read
     * @return completion
     */
    func markRead(sendable: Sendable) -> Completable

}
