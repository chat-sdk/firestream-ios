//
//  InvitationType.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

public class InvitationType: BaseType {

    public static let Chat = "chat"

    public static func chat() -> InvitationType {
        return InvitationType(Chat)
    }

}
