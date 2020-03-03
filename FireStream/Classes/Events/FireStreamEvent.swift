//
//  FireStreamEvent.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

public class FireStreamEvent<T> {

    internal var payload: T?
    internal var type: EventType

    public init(_ payload: T, _ type: EventType) {
        self.payload = payload
        self.type = type
    }

    public init(_ type: EventType) {
        self.type = type
    }

    public func getType() -> EventType {
        return self.type
    }

    public func typeIs(_ type: EventType) -> Bool {
        return self.type == type
    }

    public func get() -> T? {
        return self.payload
    }

    public class func added<T>(_ payload: T) -> FireStreamEvent<T> {
        return FireStreamEvent<T>(payload, EventType.Added)
    }

    public class func removed<T>(_ payload: T) -> FireStreamEvent<T> {
        return FireStreamEvent<T>(payload, EventType.Removed)
    }

    public class func modified<T>(_ payload: T) -> FireStreamEvent<T> {
        return FireStreamEvent<T>(payload, EventType.Modified)
    }

    public func to<W>(_ payload: W) -> FireStreamEvent<W> {
        return FireStreamEvent<W>(payload, type)
    }

}
