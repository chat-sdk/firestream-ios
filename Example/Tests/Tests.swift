import XCTest
import FireStream
import Firebase
import RxSwift

typealias FSError = FireStreamError
typealias FSEvent = FireStreamEvent
typealias FSUser = FireStreamUser

class Tests: XCTestCase {

    let testUserJohn = FSUser("13k1gXOyO0NG41HpQnO4yOplRQL2", RoleType.watcher())
    let testUserAlex = FSUser("4qnJbkDFMbaKkmYcS7GTQvhsxHE3", RoleType.admin())
    let testUserMike = FSUser("utSRkZHrNghKKRFlptTzziqqM7I3", RoleType.banned())

    let disposeBag = DisposeBag()

    class func authenticate() -> Completable {
        return Completable.create { emitter in
            Auth.auth().signIn(withEmail: "node@mail.com", password: "pass1234") { (result, error) in
                if let error = error {
                    emitter(.error(error))
                } else {
                    emitter(.completed)
                }
            }
            return Disposables.create()
        }
    }

    class func connect() -> Completable {
        return authenticate().andThen(Completable.create { emitter in
            return Fire.stream().getConnectionEvents().subscribe(onNext: { connectionEvent in
                if connectionEvent.getType() == .DidConnect {
                    emitter(.completed)
                }
            }, onError: { error in
                emitter(.error(error))
            })
        })
    }

    override class func setUp() {
        super.setUp()
        FirebaseApp.configure()
        Fire.stream().initialize()
    }

    override class func tearDown() {
        Fire.stream().disconnect()
        super.tearDown()
    }

    func users() -> [FSUser] {
        return [testUserJohn, testUserAlex, testUserMike]
    }

    func usersNotMe() -> [FSUser] {
        return users().filter { !$0.isMe() }
    }

    func addContact() -> Completable {
        return Completable.deferred {
            let user = self.testUserJohn
            return Fire.stream().addContact(user, ContactType.contact())
                .andThen(Completable.create(subscribe: { emitter in
                    // Check that it exists in the contact list
                    let contacts = Fire.stream().getContacts()
                    
                    if contacts.count != 1 {
                        emitter(.error(FSError("Contact size must be 1")))
                    } else if !contacts[0].equals(user) {
                        emitter(.error(FSError("Correct user not added to contacts")))
                    } else {
                        emitter(.completed)
                    }
                    return Disposables.create()
                }))
        }
    }

    func getContactAdded() -> Completable {
        return Completable.deferred {
            let user = self.testUserJohn
            return Completable.create(subscribe: { emitter in
                return Fire.stream().getContactEvents().sinceLastEvent().subscribe(onNext: { userEvent in
                    if userEvent.typeIs(EventType.Added) {
                        if let u = userEvent.get(), u.equals(user) {
                            emitter(.completed)
                        } else {
                            emitter(.error(FSError("Wrong user added")))
                        }
                    } else {
                        emitter(.error(FSError("No contact added")))
                    }
                }, onError: { emitter(.error($0)) })
            })
        }
    }

    func deleteContact() -> Completable {
        return Completable.deferred {
            let user = self.testUserJohn
            return Fire.stream().removeContact(user)
                .andThen(Completable.create(subscribe: { emitter in
                    // Check that it exists in the contact list
                    let contacts = Fire.stream().getContacts()

                    if contacts.count != 0 {
                        emitter(.error(FSError("Contact size must be 0")))
                    } else {
                        emitter(.completed)
                    }
                    return Disposables.create()
                }))
        }
    }

    func getContactRemoved() -> Completable {
        return Completable.deferred {
            let user = self.testUserJohn
            return Completable.create(subscribe: { emitter in
                return Fire.stream().getContactEvents().sinceLastEvent().subscribe(onNext: { userEvent in
                    if userEvent.typeIs(EventType.Removed) {
                        if let u = userEvent.get(), u.equals(user) {
                            emitter(.completed)
                        } else {
                            emitter(.error(FSError("Wrong user removed")))
                        }
                    } else {
                        emitter(.error(FSError("No contact removed")))
                    }
                }, onError: { emitter(.error($0)) })
            })
        }
    }

    func createChat() -> Completable {
        return Completable.deferred {
            let chatName = "Test"
            let chatImageURL = "https://chatsdk.co/wp-content/uploads/2017/01/image_message-407x389.jpg"
            let customData: [String: Any] = [
                "TestKey": "TestValue",
                "Key2": 999
            ]
            return Completable.create { emitter in
                Fire.stream().createChat(chatName, chatImageURL, customData, self.users()).subscribe(onSuccess: { chat in
                    // Check the name matches
                    if chat.getName() != chatName {
                        emitter(.error(FSError("Name mismatch")))
                    }

                    if chat.getImageURL() != chatImageURL {
                        emitter(.error(FSError("Image url mismatch")))
                    }

                    // Check the ID type set
                    if chat.getId().isEmpty {
                        emitter(.error(FSError("Chat id not set")))
                    }

                    if !customData.equals(chat.getCustomData()) {
                        emitter(.error(FSError("Custom data value mismatch")))
                    }

                    // Check the users
                    for user in chat.getUsers() {
                        for u in self.users() {
                            if user.equals(u) && !user.isMe() {
                                if !user.equalsRoleType(u) {
                                    emitter(.error(FSError("Role type mismatch")))
                                }
                            }
                        }
                        if user.isMe() && !user.equalsRoleType(RoleType.owner()) {
                            emitter(.error(FSError("Creator user not owner")))
                        }
                    }

                    emitter(.completed)

                }, onError: { emitter(.error($0)) })
            }
        }
    }

    func modifyChat() -> Completable {
        return Completable.deferred {
            let chatName = "Test2"
            let chatImageURL = "http://chatsdk.co/wp-content/uploads/2019/03/ic_launcher_big.png"
            let customData: [String: Any] = [
                "TestKey3": "TestValuexx",
                "Key4": 88
            ]
            let chats = Fire.stream().getChats()

            if chats.count == 0 {
                return Completable.error(FSError("Chat doesn't exist"))
            }

            return Completable.create { emitter in
                let chat = chats[0]

                var nameEvents = [String]()
                var imageURLEvents = [String]()
                var customDataEvents = [[String: Any]]()
                var userEvents = [FSEvent<FSUser>]()

                var removedUsers = [FSUser]()
                var addedUsers = [FSUser]()

                chat.getNameChangeEvents().subscribe(
                    onNext: { nameEvents.append($0) },
                    onError: { emitter(.error($0)) }
                ).disposed(by: self.disposeBag)

                chat.getImageURLChangeEvents().subscribe(
                    onNext: { imageURLEvents.append($0) },
                    onError: { emitter(.error($0)) }
                ).disposed(by: self.disposeBag)

                chat.getCustomDataChangedEvents().subscribe(
                    onNext: { customDataEvents.append($0) },
                    onError: { emitter(.error($0)) }
                ).disposed(by: self.disposeBag)

                let userEventsDisposable = chat.getUserEvents().newEvents().subscribe(
                    onNext: { userEvent in
                        if userEvent.typeIs(EventType.Modified) {
                            userEvents.append(userEvent)
                        } else {
                            emitter(.error(FSError("Add or Remove User event when modify expected")))
                        }
                    },
                    onError: { emitter(.error($0)) }
                )

                chat.setName(chatName).subscribe(
                    onCompleted: {
                        if chat.getName() != chatName {
                            emitter(.error(FSError("Chat name not updated")))
                        }
                    },
                    onError: { emitter(.error($0)) }
                ).disposed(by: self.disposeBag)

                chat.setImageURL(chatImageURL).subscribe(
                    onCompleted: {
                        if chat.getImageURL() != chatImageURL {
                            emitter(.error(FSError("Chat image URL not updated")))
                        }
                    },
                    onError: { emitter(.error($0)) }
                ).disposed(by: self.disposeBag)

                chat.setCustomData(customData).subscribe(
                    onCompleted: {
                        if !customData.equals(chat.getCustomData()) {
                            emitter(.error(FSError("Chat custom data not updated")))
                        }
                    },
                    onError: { emitter(.error($0)) }
                ).disposed(by: self.disposeBag)

                for u in self.users() {
                    if !u.isMe(), let roleType = u.getRoleType() {
                        chat.setRole(u, roleType).subscribe(
                            onCompleted: {
                                // Check the user's role
                                if !roleType.equals(chat.getRoleType(u)) {
                                    emitter(.error(FSError("User role updated not correct")))
                                }
                            },
                            onError: { emitter(.error($0)) }
                        ).disposed(by: self.disposeBag)
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {

                    // Check the chat type correct
                    // Check the name matches
                    if chat.getName() != chatName {
                        emitter(.error(FSError("Name mismatch")))
                    }

                    if chat.getImageURL() != chatImageURL {
                        emitter(.error(FSError("Image URL mismatch")))
                    }

                    if !customData.equals(chat.getCustomData()) {
                        emitter(.error(FSError("Custom data mismatch")))
                    }

                    // Check the users
                    for user in chat.getUsers() {
                        for u in self.users() {
                            if user.equals(u) && !user.isMe(), let roleType = user.getRoleType() {
                                if !roleType.equals(u.getRoleType()) {
                                    emitter(.error(FSError("Role type mismatch")))
                                }
                            }
                        }
                        if user.isMe() {
                            if let roleType = user.getRoleType() {
                                if !roleType.equals(RoleType.owner()) {
                                    emitter(.error(FSError("Creator user not owner")))
                                }
                            } else {
                                emitter(.error(FSError("Could not RoleType of creator")))
                            }
                        }
                    }

                    if nameEvents.count == 0 {
                        emitter(.error(FSError("Name not set from stream")))
                    } else {
                        if nameEvents.last != chatName {
                            emitter(.error(FSError("Name from stream incorrect")))
                        }
                    }

                    if imageURLEvents.count == 0 {
                        emitter(.error(FSError("ImageURL not set from stream")))
                    } else {
                        if imageURLEvents.last != chatImageURL {
                            emitter(.error(FSError("ImageURL from stream incorrect")))
                        }
                    }

                    if customDataEvents.count == 0 {
                        emitter(.error(FSError("Custom data not set from stream")))
                    } else {
                        if !customData.equals(customDataEvents.last) {
                            emitter(.error(FSError("Custom data from stream incorrect")))
                        }
                    }

                    // FIXME: Why are we not receiving user events?
//                    if userEvents.count == 0 {
//                        emitter(.error(FSError("User events not received")))
//                    } else {
//                        for ue in userEvents {
//                            for u in self.users() {
//                                if let roleType = ue.get()?.getRoleType() {
//                                    if !roleType.equals(u.getRoleType()) {
//                                        emitter(.error(FSError("Role type not updated correctly")))
//                                    }
//                                } else {
//                                    emitter(.error(FSError("FSEvent<FSUser>.get().getRoleType() returned nil")))
//                                }
//                            }
//                        }
//                    }

                    userEventsDisposable.dispose()

                    chat.getUserEvents().newEvents().subscribe(
                        onNext: { userEvent in
                            if userEvent.typeIs(EventType.Added), let user = userEvent.get() {
                                addedUsers.append(user)
                            }
                            else if userEvent.typeIs(EventType.Removed), let user = userEvent.get() {
                                removedUsers.append(user)
                            }
                            else {
                                emitter(.error(FSError("Modify event when added or removed expected")))
                            }
                        },
                        onError: { emitter(.error($0)) }
                    ).disposed(by: self.disposeBag)

                    // Now try to add one user and remove another user
                    let u1 = self.usersNotMe()[0]

                    chat.removeUser(u1).subscribe(
                        onCompleted: {
                            let role = chat.getRoleType(u1)
                            if role != nil {
                                emitter(.error(FSError("User removed but still exists in chat")))
                            }
                        },
                        onError: { emitter(.error($0)) }
                    ).disposed(by: self.disposeBag)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if removedUsers.count == 0 {
                            emitter(.error(FSError("User removed event didn't fire")))
                        } else {
                            if !removedUsers[0].equals(u1) {
                                emitter(.error(FSError("Removed user mismatch")))
                            }
                        }

                        chat.addUser(false, u1).subscribe(
                            onCompleted: {
                                if let role = chat.getRoleType(u1), !role.equals(u1.getRoleType()) {
                                    emitter(.error(FSError("Added user has wrong role")))
                                }
                            },
                            onError: { emitter(.error($0)) }
                        ).disposed(by: self.disposeBag)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if addedUsers.count == 0 {
                                emitter(.error(FSError("User added event didn't fire")))
                            } else {
                                if !addedUsers[0].equals(u1) {
                                    emitter(.error(FSError("Added user mismatch")))
                                }
                            }

                            emitter(.completed)
                        }
                    }
                }

                return Disposables.create()
            }
        }
    }

    func messageChat() -> Completable {
        return Completable.deferred {
            let messageReceiptId =  "XXX"
            let messageText =  "Test"
            let message = TextMessage(messageText)

            let chats = Fire.stream().getChats()
            
            if chats.count == 0 {
                return Completable.error(FSError("Chat doesn't exist"))
            }

            return Completable.create { emitter in
                let chat = chats[0]

                chat.getSendableEvents().getErrors().subscribe(
                    onNext: { emitter(.error($0)) },
                    onError: { emitter(.error($0)) }
                ).disposed(by: self.disposeBag)

                var messages = [Message]()
                var receipts = [DeliveryReceipt]()
                var typingStates = [TypingState]()

                chat.getSendableEvents().getMessages().allEvents().subscribe(
                    onNext: { event in
                        if let payload = event.get() {
                            messages.append(payload)
                        }
                    },
                    onError: { emitter(.error($0)) }
                ).disposed(by: self.disposeBag)

                chat.getSendableEvents().getDeliveryReceipts().allEvents().subscribe(
                    onNext: { event in
                        if let payload = event.get() {
                            receipts.append(payload)
                        }
                    },
                    onError: { emitter(.error($0)) }
                ).disposed(by: self.disposeBag)

                chat.getSendableEvents().getTypingStates().allEvents().subscribe(
                    onNext: { event in
                        if let payload = event.get() {
                            typingStates.append(payload)
                        }
                    },
                    onError: { emitter(.error($0)) }
                ).disposed(by: self.disposeBag)

                // Send a message
                chat.send(message).do(onCompleted: {
                    // The chat should not yet contain the message - messages are only received via events
                    if chat.getSendables(SendableType.message()).count != 1 {
                        emitter(.error(FSError("Message not in sendables when it should be")))
                    } else {
                        let message = TextMessage.fromSendable(chat.getSendables(SendableType.message())[0])
                        if message.getText() != messageText {
                            emitter(.error(FSError("Message text mismatch")))
                        }
                    }
                }).concat(chat.sendTypingIndicator(TypingStateType.typing())).do(onCompleted: {
                    if chat.getSendables(SendableType.typingState()).count != 1 {
                        emitter(.error(FSError("Typing state not in sendables when it should be")))
                    } else {
                        let state = TypingState.fromSendable((chat.getSendables(SendableType.typingState())[0]))
                        if !state.getTypingStateType().equals(TypingStateType.typing()) {
                            emitter(.error(FSError("Typing state type mismatch")))
                        }
                    }
                }).concat(chat.sendDeliveryReceipt(DeliveryReceiptType.received(), messageReceiptId)).do(onCompleted: {
                    if chat.getSendables(SendableType.deliveryReceipt()).count != 1 {
                        emitter(.error(FSError("delivery receipt not in sendables when it should be")))
                    } else {
                        let receipt = DeliveryReceipt.fromSendable((chat.getSendables(SendableType.deliveryReceipt())[0]))
                        if !receipt.getDeliveryReceiptType().equals(DeliveryReceiptType.received()) {
                            emitter(.error(FSError("Delivery receipt type mismatch")))
                        }
                        do {
                            if try receipt.getMessageId() != messageReceiptId {
                                emitter(.error(FSError("Delivery receipt message id incorrect")))
                            }
                        } catch {
                            emitter(.error(error))
                        }
                    }
                }).subscribe(onError: { emitter(.error($0)) }).disposed(by: self.disposeBag)

                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    // Check that the chat now has the message

                    if messages.count != 0 {
                        let message = TextMessage.fromSendable(messages[0])
                        if message.getText() != messageText {
                            emitter(.error(FSError("Message text incorrect")))
                        }
                    } else {
                        emitter(.error(FSError("Chat doesn't contain message")))
                    }

                    if receipts.count != 0 {
                        let receipt = DeliveryReceipt.fromSendable(receipts[0])
                        if !receipt.getDeliveryReceiptType().equals(DeliveryReceiptType.received()) {
                            emitter(.error(FSError("Delivery receipt type incorrect")))
                        }
                        do {
                            if try receipt.getMessageId() != messageReceiptId {
                                emitter(.error(FSError("Delivery receipt message id incorrect")))
                            }
                        } catch {
                            emitter(.error(error))
                        }
                    } else {
                        emitter(.error(FSError("Chat doesn't contain delivery receipt")))
                    }

                    if typingStates.count != 0 {
                        let state = TypingState.fromSendable(typingStates[0])
                        if !state.getTypingStateType().equals(TypingStateType.typing()) {
                            emitter(.error(FSError("Typing state type incorrect")))
                        }
                    } else {
                        emitter(.error(FSError("Chat doesn't contain typing state")))
                    }

                    // Send 10 messages
                    var completables = [Completable]()
                    for i in 0..<10 {
                        completables.append(chat.sendMessageWithText("\(i)"))
                    }

                    Completable.concat(completables).subscribe(
                        onCompleted: {
                            // The messages should have been delivered by now
                            // Make a query to get all but the first and last messages in order
                            let sendables = chat.getSendables()
                            if sendables.count != 13 {
                                emitter(.error(FSError("There should be 13 messages and there are not")))
                            } else {
                                let fromDate = Date(timestamp: 0)
                                guard let toDate = DateComponents(calendar: .current, year: 3000).date else {
                                    emitter(.error(FSError("Could not create toDate")))
                                    return
                                }
                                chat.loadMoreMessages(fromDate, toDate).subscribe(
                                    onSuccess: { sendablesAll in
                                        let allFirst = sendablesAll[0]
                                        let allSecond = sendablesAll[1]
                                        let allLast = sendablesAll[sendablesAll.count - 1]

                                        // Check first and last messages
                                        if !allFirst.equals(sendables[0]) {
                                            emitter(.error(FSError("All first message incorrect")))
                                        }
                                        if !allLast.equals(sendables[sendables.count - 1]) {
                                            emitter(.error(FSError("All last message incorrect")))
                                        }
                                        if sendablesAll.count != sendables.count {
                                            emitter(.error(FSError("All size mismatch")))
                                        }

                                        let indexOfFirst: Int = 0
                                        let indexOfLast: Int = sendablesAll.count - 1
                                        let limit: Int = 5

                                        let fromSendable = sendablesAll[indexOfFirst]
                                        let toSendable = sendablesAll[indexOfLast]

                                        // Get the date of the second and penultimate
                                        guard let from = fromSendable.getDate() else {
                                            emitter(.error(FSError("Could not get fromDate from sendable")))
                                            return
                                        }
                                        guard let to = toSendable.getDate() else {
                                            emitter(.error(FSError("Could not get toDate from sendable")))
                                            return
                                        }

                                        // There is a timing issue here in that the date of the sendable
                                        // will actually be a Firebase prediction rather than the actual time recorded on the server
                                        chat.loadMoreMessages(from, to).do(
                                            onSuccess: { sendablesFromTo in
                                                if sendablesFromTo.count != 12 {
                                                    emitter(.error(FSError("From/To Sendable size incorrect")))
                                                }

                                                let first = sendablesFromTo[0]
                                                let second = sendablesFromTo[1]
                                                let last = sendablesFromTo[sendablesFromTo.count - 1]

                                                // First message should be the same as the second overall message
                                                if !first.equals(allSecond) {
                                                    emitter(.error(FSError("From/To First message incorrect")))
                                                }
                                                if !last.equals(toSendable) {
                                                    emitter(.error(FSError("From/To Last message incorrect")))
                                                }
                                                // Check the first message type on or after the from date
                                                if first.getDate()!.timestamp <= from.timestamp {
                                                    emitter(.error(FSError("From/To First message type before fro)) time")))
                                                }
                                                if last.getDate()!.timestamp > to.timestamp {
                                                    emitter(.error(FSError("From/To Last message type after to time")))
                                                }
                                                if second.getDate()!.timestamp < first.getDate()!.timestamp {
                                                    emitter(.error(FSError("From/To Messages order incorrect")))
                                                }
                                            }
                                        ).asCompletable().concat(chat.loadMoreMessagesFrom(from, limit).do(
                                            onSuccess: { sendablesFrom in
                                                if sendablesFrom.count != limit {
                                                    emitter(.error(FSError("From Sendable size incorrect")))
                                                }

                                                let first = sendablesFrom[0]
                                                let second = sendablesFrom[1]
                                                let last = sendablesFrom[sendablesFrom.count - 1]

                                                if !allSecond.equals(first) {
                                                    emitter(.error(FSError("From First message incorrect")))
                                                }
                                                if !sendablesAll[limit].equals(last) {
                                                    emitter(.error(FSError("From Last message incorrect")))
                                                }

                                                // Check the first message type on or after the from date
                                                if first.getDate()!.timestamp <= from.timestamp {
                                                    emitter(.error(FSError("From First message type before from time")))
                                                }
                                                if second.getDate()!.timestamp < first.getDate()!.timestamp {
                                                    emitter(.error(FSError("From Messages order incorrect")))
                                                }
                                            }
                                        ).asCompletable()).concat(chat.loadMoreMessagesTo(to, limit).do(
                                            onSuccess: { sendablesTo in
                                                let first = sendablesTo[0]
                                                let second = sendablesTo[1]
                                                let last = sendablesTo[sendablesTo.count - 1]

                                                if sendablesTo.count != limit {
                                                    emitter(.error(FSError("To Sendable size incorrect")))
                                                }
                                                if !first.equals(sendablesAll[sendablesAll.count - limit]) {
                                                    emitter(.error(FSError("To First message incorrect")))
                                                }
                                                if !toSendable.equals(last) {
                                                    emitter(.error(FSError("To Last message incorrect")))
                                                }
                                                if last.getDate()!.timestamp > to.timestamp {
                                                    emitter(.error(FSError("To Last message type after to time")))
                                                }
                                                if second.getDate()!.timestamp < first.getDate()!.timestamp {
                                                    emitter(.error(FSError("To Messages order incorrect")))
                                                }
                                            }
                                        ).asCompletable()).subscribe(
                                            onCompleted: { emitter(.completed) },
                                            onError: { emitter(.error($0)) }
                                        ).disposed(by: self.disposeBag)
                                    },
                                    onError: { emitter(.error($0)) }
                                ).disposed(by: self.disposeBag)
                            }
                        },
                        onError: { emitter(.error($0)) }
                    ).disposed(by: self.disposeBag)
                }
                return Disposables.create()
            }
        }
    }

    func test() {
        let expectation = XCTestExpectation(description: "Perform all tests")
        Self.connect()
            .do(onError: { XCTFail($0.localizedDescription) })
            .andThen(addContact())
            .do(onError: { XCTFail($0.localizedDescription) })
            .andThen(getContactAdded())
            .do(onError: { XCTFail($0.localizedDescription) })
            .andThen(deleteContact())
            .do(onError: { XCTFail($0.localizedDescription) })
            .andThen(getContactRemoved())
            .do(onError: { XCTFail($0.localizedDescription) })
            .andThen(createChat())
            .do(onError: { XCTFail($0.localizedDescription) })
            .andThen(modifyChat())
            .do(onError: { XCTFail($0.localizedDescription) })
            .andThen(messageChat())
            .do(onError: { XCTFail($0.localizedDescription) })
            .subscribe(
                onCompleted: expectation.fulfill,
                onError: { XCTFail($0.localizedDescription) }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 30.0)
    }

}

fileprivate extension Dictionary {
    func equals(_ data: [AnyHashable: Any]?) -> Bool {
        if let data = data {
            return (self as NSDictionary).isEqual(to: data)
        } else {
            return false
        }
    }
}
