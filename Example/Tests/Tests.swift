import XCTest
import FireStream
import Firebase
import RxSwift

typealias FSError = FireStreamError

class Tests: XCTestCase {

    static let testUserJohn = FireStreamUser("13k1gXOyO0NG41HpQnO4yOplRQL2", RoleType.watcher())
    static let testUserAlex = FireStreamUser("4qnJbkDFMbaKkmYcS7GTQvhsxHE3", RoleType.admin())
    static let testUserMike = FireStreamUser("utSRkZHrNghKKRFlptTzziqqM7I3", RoleType.banned())
    static let testUsers = [testUserJohn, testUserAlex, testUserMike]

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

    func addContact() -> Completable {
        return Completable.deferred {
            let user = Self.testUserJohn
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
            let user = Self.testUserJohn
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
            let user = Self.testUserJohn
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
            let user = Self.testUserJohn
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

    func test() {
        let expectation = XCTestExpectation(description: "Perform all tests")
        _ = Self.connect()
            .do(onError: { XCTFail($0.localizedDescription) })
            .andThen(addContact())
            .do(onError: { XCTFail($0.localizedDescription) })
            .andThen(getContactAdded())
            .do(onError: { XCTFail($0.localizedDescription) })
            .andThen(deleteContact())
            .do(onError: { XCTFail($0.localizedDescription) })
            .andThen(getContactRemoved())
            .do(onError: { XCTFail($0.localizedDescription) })
            .subscribe(onCompleted: expectation.fulfill)

        wait(for: [expectation], timeout: 10.0)
    }

}
