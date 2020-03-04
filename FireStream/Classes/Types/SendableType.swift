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

    public class func message() -> SendableType {
        return SendableType(Message)
    }

    public class func deliveryReceipt() -> SendableType {
        return SendableType(DeliveryReceipt)
    }

    public class func typingState() -> SendableType {
        return SendableType(TypingState)
    }

    public class func presence() -> SendableType {
        return SendableType(Presence)
    }

    public class func invitation() -> SendableType {
        return SendableType(Invitation)
    }

    public func equals(_ type: SendableType?) -> Bool {
        return self.get() == type?.get()
    }

}
