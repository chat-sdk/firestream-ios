//
//  Message.swift
//  FireStream
//
//  Created by Pepe Becker on 1/29/20.
//

public class Message: Sendable {

    public required init() {
        super.init()
        self.type = SendableType.Message
    }

    public convenience init(body: [String: Any]) {
        self.init()
        self.body = body
    }

    public convenience init(id: String, body: [String: Any]) {
        self.init(body: body)
        self.id = id
    }

    public static func fromSendable(_ sendable: Sendable) -> Message {
        return super.fromSendable(sendable)
    }

}
