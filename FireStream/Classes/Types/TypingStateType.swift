//
//  TypingStateType.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

public class TypingStateType: BaseType {

    public static let Typing = "typing"

    public class func typing() -> TypingStateType {
        return TypingStateType(Typing)
    }

    public class func none() -> TypingStateType {
        return super.none()
    }

}
