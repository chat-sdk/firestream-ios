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

    static func authenticate() -> Completable {
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

    static func connect() -> Completable {
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
            .subscribe(onCompleted: expectation.fulfill)
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 16.0)
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
