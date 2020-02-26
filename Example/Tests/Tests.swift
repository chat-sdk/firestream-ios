import XCTest
import FireStream
import Firebase
import RxSwift

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

    override class func setUp() {
        super.setUp()
        FirebaseApp.configure()
        Fire.stream().initialize()
    }

    override class func tearDown() {
        Fire.stream().disconnect()
        super.tearDown()
    }

    func testAddContact() {
        let expectation = XCTestExpectation(description: "Add contact")
        _ = Self.authenticate().subscribe(onCompleted: {
            let user = Self.testUserJohn
            _ = Fire.stream().addContact(user, ContactType.contact()).subscribe(onCompleted: {
                // Check that it exists in the contact list
                let contacts = Fire.stream().getContacts()

                if contacts.count != 1 {
                    XCTFail("Contact size must be 1")
                } else if !contacts[0].equals(user) {
                    XCTFail("Correct user not added to contacts")
                } else {
                    expectation.fulfill()
                }
            }, onError: { XCTFail($0.localizedDescription) })
        }, onError: { XCTFail($0.localizedDescription) })
        wait(for: [expectation], timeout: 10.0)
    }
    
}
