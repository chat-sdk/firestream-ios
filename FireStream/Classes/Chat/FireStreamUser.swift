//
//  FireStreamUser.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

public class FireStreamUser: User {

    public static func fromUser(user: User) -> FireStreamUser {
        let fireStreamUser = FireStreamUser(id: user.getId())
        fireStreamUser.setContactType(contactType: user.getContactType())
        fireStreamUser.setRoleType(roleType: user.getRoleType())
        return fireStreamUser
    }

}
