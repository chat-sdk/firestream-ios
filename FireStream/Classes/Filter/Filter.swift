//
//  Filter.swift
//  FireStream
//
//  Created by Pepe Becker on 2/14/20.
//

import UIKit

public typealias Predicate<T> = (T) -> Bool

public class Filter {

    public class func bySendableType<T: Sendable>(_ types: SendableType...) -> Predicate<FireStreamEvent<T>> {
        return { e in
            for type in types {
                if e.get()!.getType() == type.get() {
                    return true
                }
            }
            return false
        }
    }

    public class func notFromMe<T: Sendable>() -> Predicate<FireStreamEvent<T>> {
        return { e in e.get()?.getFrom() != Fire.stream().currentUserId() }
    }

    public class func byEventType<T: Sendable>(_ types: EventType...) -> Predicate<FireStreamEvent<T>> {
        return { e in
            for type in types {
                if e.getType() == type {
                    return true
                }
            }
            return false
        }
    }

    public class func eventBySendableType<T: Sendable>(_ types: SendableType...) -> Predicate<FireStreamEvent<T>> {
        return { e in
            for type in types {
                if e.get()?.getType() == type.get() {
                    return true
                }
            }
            return false
        }
    }

    public class func and<T: Sendable>(_ predicates: Predicate<FireStreamEvent<T>>...) -> Predicate<FireStreamEvent<T>> {
        return and(predicates)
    }

    public class func and<T: Sendable>(_ predicates: [Predicate<FireStreamEvent<T>>]) -> Predicate<FireStreamEvent<T>> {
        return { event in
            for p in predicates {
                if !p(event) {
                    return false
                }
            }
            return true
        }
    }

}
