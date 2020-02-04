//
//  Presence.swift
//  FireStream
//
//  Created by Pepe Becker on 1/29/20.
//

public class Presence: Sendable {

    public static let PresenceKey = "presence"

    public required init() {
        super.init()
        self.type = SendableType.Presence
    }

    public convenience init(type: PresenceType) {
        self.init()
        super.setBodyType(type)
    }

    public override func getBodyType() -> PresenceType {
        return PresenceType(super.getBodyType())
    }

    public static func fromSendable(_ sendable: Sendable) -> Presence {
        return super.fromSendable(sendable)
    }

}
