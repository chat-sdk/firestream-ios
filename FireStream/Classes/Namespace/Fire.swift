//
//  Fire.swift
//  FireStream
//
//  Created by Pepe Becker on 2/14/20.
//

public class Fire {

    public class func internalApi() -> FireStream {
        return FireStream.shared()
    }

    public class func stream() -> PFireStream {
        return FireStream.shared()
    }

}
