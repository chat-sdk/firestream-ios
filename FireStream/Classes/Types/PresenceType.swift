//
//  PresenceType.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

public class PresenceType: BaseType {

    public static let Unavailable = "unavailable"
    public static let Busy = "busy"
    public static let ExtendedAway = "xa"
    public static let Available = "available"

    public class func unavailable() -> PresenceType {
        return PresenceType(Unavailable)
    }

    public class func busy() -> PresenceType {
        return PresenceType(Busy)
    }

    public class func extendedAway() -> PresenceType {
        return PresenceType(ExtendedAway)
    }

    public class func available() -> PresenceType {
        return PresenceType(Available)
    }

}
