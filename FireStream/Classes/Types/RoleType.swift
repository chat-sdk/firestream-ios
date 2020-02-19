//
//  RoleType.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

public class RoleType: BaseType {

    /**
     * They have full access rights, can add and remove admins
     */
    public static let Owner = "owner"

    /**
     * An admin can change the status of any lower member, also update the name, image and custom data
     */
    public static let Admin = "admin"

    /**
     * Standard member of the chat, has write access but can't change roles
     */
    public static let Member = "member"

    /**
     * Read-only access
     */
    public static let Watcher = "watcher"

    /**
     * Cannot access the chat, cannot be added
     */
    public static let Banned = "banned"

    public static func owner() -> RoleType {
        return RoleType(Owner)
    }

    public static func admin() -> RoleType {
        return RoleType(Admin)
    }

    public static func member() -> RoleType {
        return RoleType(Member)
    }

    public static func watcher() -> RoleType {
        return RoleType(Watcher)
    }

    public static func banned() -> RoleType {
        return RoleType(Banned)
    }

    public func data() -> [String: Any] {
        var data = [String: Any]()
        data[Keys.Role] = self.get()
        return data
    }

    public func ge(_ permission: RoleType) -> Bool {
        return toLevel() <= permission.toLevel()
    }

    internal func toLevel() -> Int {
        if self.type.count > 0 {
            if type == Self.Owner {
                return 0
            }
            if type == Self.Admin {
                return 1
            }
            if type == Self.Member {
                return 2
            }
            if type == Self.Watcher {
                return 3
            }
            if type == Self.Banned {
                return 4
            }
        }
        return 5
    }

    public func stringValue() -> String {
        if equals(Self.owner()) {
            return "R.string.owner"
        }
        if equals(Self.admin()) {
            return "R.string.admin"
        }
        if equals(Self.member()) {
            return "R.string.member"
        }
        if equals(Self.watcher()) {
            return "R.string.watcher"
        }
        if equals(Self.banned()) {
            return "R.string.banned"
        }
        return ""
    }

    public static func allStringValues() -> [String] {
        return allStringValuesExcluding()
    }

    public static func allStringValuesExcluding(_ excluding: RoleType...) -> [String] {
        return allStringValuesExcluding(excluding)
    }

    public static func allStringValuesExcluding(_ excluding: [RoleType]) -> [String] {
        return rolesToStringValues(allExcluding(excluding))
    }

    public static func all() -> [RoleType] {
        return allExcluding()
    }

    public static func allExcluding(_ excluding: RoleType...) -> [RoleType] {
        return allExcluding(excluding)
    }

    public static func allExcluding(_ excluding: [RoleType]) -> [RoleType] {
        var list = [owner(), admin(), member(), watcher(), banned()]
        for rt in excluding {
            list.removeAll(where: { roleType -> Bool in
                roleType.equals(rt)
            })
        }
        return list
    }

    public static func rolesToStringValues(_ roleTypes: [RoleType]) -> [String] {
        var stringValues = [String]()

        for rt in roleTypes {
            stringValues.append(rt.stringValue())
        }

        return stringValues
    }

    public static func reverseMap() -> [String: RoleType] {
        var map = [String: RoleType]()
        for roleType in self.all() {
            map[roleType.stringValue()] = roleType
        }
        return map
    }

}
