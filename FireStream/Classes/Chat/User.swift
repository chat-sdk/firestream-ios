//
//  User.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

public class User {

    internal var id: String
    internal var roleType: RoleType?
    internal var contactType: ContactType?

    public init(id: String) {
        self.id = id
    }

    public convenience init(id: String, roleType: RoleType?) {
        self.init(id: id)
        self.roleType = roleType
    }

    public convenience init(id: String, contactType: ContactType?) {
        self.init(id: id)
        self.contactType = contactType
    }

    public func getId() -> String {
        return self.id
    }

    public func setId(id: String) {
        self.id = id
    }

    public func getRoleType() -> RoleType? {
        return self.roleType
    }

    public func setRoleType(roleType: RoleType?) {
        self.roleType = roleType
    }

    public func getContactType() -> ContactType? {
        return self.contactType
    }

    public func setContactType(contactType: ContactType?) {
        self.contactType = contactType
    }

    public func equalsRoleType(rt: RoleType) -> Bool {
        return self.roleType?.equals(rt) ?? false
    }

    public func equalsRoleType(user: User) -> Bool {
        return self.roleType?.equals(user.getRoleType()) ?? false
    }

    public func equalsContactType(user: User) -> Bool {
        return self.contactType?.equals(user.getContactType()) ?? false
    }

    public func equalsContactType(ct: ContactType) -> Bool {
        return self.contactType?.equals(ct) ?? false
    }

    public func equals(user: Any) -> Bool {
        if let user = user as? User {
            return self.id == user.id
        }
        return false
    }

    public func isMe() -> Bool {
        // MARK: TODO
        // return id.equals(Fire.Stream.currentUserId());
        return false
    }

    public static func currentUser(role: RoleType?) -> User {
        return User(id: "Fire.Stream.currentUserId()", roleType: role)
    }

    public static func currentUser() -> User {
        return currentUser(role: nil)
    }

    public struct DataProvider {
        let provideFunc: (User?) -> [String: Any]

        public func data(_ user: User?) -> [String: Any] {
            return provideFunc(user)
        }
    }

    public static func dateDataProvider() -> DataProvider {
        return DataProvider { _ in
            return [
                // MARK: TODO
                // Keys.Date: Fire.privateApi().getFirebaseService().core.timestamp()
                Keys.Date: "Fire.privateApi().getFirebaseService().core.timestamp()"
            ]
        }
    }

    public static func roleTypeDataProvider() -> DataProvider {
        return DataProvider { ($0?.roleType?.data() ?? [:]) }
    }

    public static func contactTypeDataProvider() -> DataProvider {
        return DataProvider { ($0?.contactType?.data() ?? [:]) }
    }

    public static func from(event: FireStreamEvent<ListData>) throws -> User {
        guard let id = event.get()?.getId() else {
            throw FireStreamError("id of event payload is undefined")
        }
        if let role = event.get()?.get(key: Keys.Role) as? String {
            return User(id: id, roleType: RoleType(role))
        }
        if let type = event.get()?.get(key: Keys.type) as? String {
            return User(id: id, contactType: ContactType(type))
        }
        return User(id: id)
    }

}
