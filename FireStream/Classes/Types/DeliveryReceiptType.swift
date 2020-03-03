//
//  File.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

public class DeliveryReceiptType: BaseType {

    public static let Received = "received"
    public static let Read = "read"

    public class func received() -> DeliveryReceiptType {
        return DeliveryReceiptType(Received)
    }

    public class func read() -> DeliveryReceiptType {
        return DeliveryReceiptType(Read)
    }

}
