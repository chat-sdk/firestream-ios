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

    public func typeIs(type: EventType) -> Bool {
        return self.type == type
    }

    public func get() -> T? {
        return self.payload
    }

    public static func added<T>(payload: T) -> FireStreamEvent<T> {
        return FireStreamEvent<T>(payload, EventType.Added)
    }

    public static func removed<T>(payload: T) -> FireStreamEvent<T> {
        return FireStreamEvent<T>(payload, EventType.Removed)
    }

    public static func modified<T>(payload: T) -> FireStreamEvent<T> {
        return FireStreamEvent<T>(payload, EventType.Modified)
    }

    public func to<W>(_ payload: W) -> FireStreamEvent<W> {
        return FireStreamEvent<W>(payload, type)
    }

}
