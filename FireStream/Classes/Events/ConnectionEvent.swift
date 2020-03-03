//
//  ConnectionEvent.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

public class ConnectionEvent {

    public enum ConnectionEventType {
        case None
        case WillConnect
        case DidConnect
        case WillDisconnect
        case DidDisconnect
    }

    internal let type: ConnectionEventType

    internal init(_ type: ConnectionEventType) {
        self.type = type
    }

    public class func willConnect() -> ConnectionEvent {
        return ConnectionEvent(.WillConnect)
    }

    public class func didConnect() -> ConnectionEvent {
        return ConnectionEvent(.DidConnect)
    }

    public class func willDisconnect() -> ConnectionEvent {
        return ConnectionEvent(.WillDisconnect)
    }

    public class func didDisconnect() -> ConnectionEvent {
        return ConnectionEvent(.DidDisconnect)
    }

    public func getType() -> ConnectionEventType {
        return self.type
    }

}
