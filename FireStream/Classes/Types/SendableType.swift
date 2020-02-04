//
//  SendableType.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

public class SendableType: BaseType {

    public static let Message = "message"
    public static let DeliveryReceipt = "receipt"
    public static let TypingState = "typing"
    public static let Presence = "presence"
    public static let Invitation = "invitation"

    public static func message() -> SendableType {
        return SendableType(Message)
    }

    public static func deliveryReceipt() -> SendableType {
        return SendableType(DeliveryReceipt)
    }

    public static func typingState() -> SendableType {
        return SendableType(TypingState)
    }

    public static func presence() -> SendableType {
        return SendableType(Presence)
    }

    public static func invitation() -> SendableType {
        return SendableType(Invitation)
    }

}
