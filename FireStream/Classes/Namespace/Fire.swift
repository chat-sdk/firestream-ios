//
//  Fire.swift
//  FireStream
//
//  Created by Pepe Becker on 2/14/20.
//

public class Fire {

    public static func internalApi() -> FireStream {
        return FireStream.shared()
    }

    public static func stream() -> PFireStream {
        return FireStream.shared()
    }

}
