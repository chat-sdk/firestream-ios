//
//  TextMessage.swift
//  FireStream
//
//  Created by Pepe Becker on 1/29/20.
//

public class TextMessage: Message {

    public static let TextKey = "text"

    public convenience init(text: String) {
        self.init()
        self.body?[Self.TextKey] = text
    }

    public func getText() -> String? {
        return body?[Self.TextKey] as? String
    }

    // MARK: TODO
    // public static func fromSendable(_ sendable: Sendable) -> TextMessage {
    //     return super.fromSendable(sendable)
    // }

}
