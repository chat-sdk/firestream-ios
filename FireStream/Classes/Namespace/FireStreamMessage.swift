//
//  FireStreamMessage.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

public class FireStreamMessage: Message {

    public static func fromMessage(_ message: Message) -> FireStreamMessage {
        let firestreamMessage = FireStreamMessage()
        message.copyTo(firestreamMessage)
        return firestreamMessage
    }

    // TODO: is this required?
    // public static func fromSendable(_ sendable: Sendable) -> FireStreamMessage {
    //     let message = FireStreamMessage()
    //     sendable.copyTo(message)
    //     return message
    // }

}
