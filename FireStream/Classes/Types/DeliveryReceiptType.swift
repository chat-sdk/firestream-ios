//
//  File.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

public class DeliveryReceiptType: BaseType {

    public static let Received = "received"
    public static let Read = "read"

    public static func received() -> DeliveryReceiptType {
        return DeliveryReceiptType(Received)
    }

    public static func read() -> DeliveryReceiptType {
        return DeliveryReceiptType(Read)
    }

}
