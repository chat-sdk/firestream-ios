//
//  FireStreamUser.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

public class FireStreamUser {

    internal var id: String
    internal var roleType: RoleType?
    internal var contactType: ContactType?

    public init(_ id: String) {
        self.id = id
    }

    public convenience init(_ id: String, _ roleType: RoleType?) {
        self.init(id)
        self.roleType = roleType
    }

    public convenience init(_ id: String, _ contactType: ContactType?) {
        self.init(id)
        self.contactType = contactType
    }

    public func getId() -> String {
        return self.id
    }

    public func setId(_ id: String) {
        self.id = id
    }

    public func getRoleType() -> RoleType? {
        return self.roleType
    }

    public func setRoleType(_ roleType: RoleType?) {
        self.roleType = roleType
    }

    public func getContactType() -> ContactType? {
        return self.contactType
    }

    public func setContactType(_ contactType: ContactType?) {
        self.contactType = contactType
    }

    public func equalsRoleType(_ rt: RoleType) -> Bool {
        return self.roleType?.equals(rt) ?? false
    }

    public func equalsRoleType(_ user: FireStreamUser) -> Bool {
        return self.roleType?.equals(user.getRoleType()) ?? false
    }

    public func equalsContactType(_ user: FireStreamUser) -> Bool {
        return self.contactType?.equals(user.getContactType()) ?? false
    }

    public func equalsContactType(_ ct: ContactType) -> Bool {
        return self.contactType?.equals(ct) ?? false
    }

    public func equals(_ user: FireStreamUser?) -> Bool {
        if let user = user {
            return self.id == user.id
        }
        return false
    }

    public func isMe() -> Bool {
        return self.id == Fire.internalApi().currentUserId()
    }

    public class func currentUser(_ role: RoleType?) -> FireStreamUser? {
        if let userId = Fire.internalApi().currentUserId() {
            return FireStreamUser(userId, role)
        }
        return nil
    }

    public class func currentUser() -> FireStreamUser? {
        return currentUser(nil)
    }

    public struct DataProvider {
        let provideFunc: (FireStreamUser?) -> [String: Any]

        public func data(_ user: FireStreamUser?) -> [String: Any] {
            return provideFunc(user)
        }
    }

    public class func dateDataProvider() -> DataProvider {
        if let firebaseService = Fire.internalApi().getFirebaseService() {
            return DataProvider { _ in
                return [Keys.Date: firebaseService.core.timestamp()]
            }
        }
        return DataProvider { _ in
            return [Keys.Date: Date()]
        }
    }

    public class func roleTypeDataProvider() -> DataProvider {
        return DataProvider { ($0?.roleType?.data() ?? [:]) }
    }

    public class func contactTypeDataProvider() -> DataProvider {
        return DataProvider { ($0?.contactType?.data() ?? [:]) }
    }

    public class func from(_ event: FireStreamEvent<ListData>) throws -> FireStreamUser {
        guard let id = event.get()?.getId() else {
            throw FireStreamError("id of event payload is undefined")
        }
        if let role = event.get()?.get(Keys.Role) as? String {
            return FireStreamUser(id, RoleType(role))
        }
        if let type = event.get()?.get(Keys.type) as? String {
            return FireStreamUser(id, ContactType(type))
        }
        return FireStreamUser(id)
    }

}
