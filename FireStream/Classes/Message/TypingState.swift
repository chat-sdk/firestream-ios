//
//  TypingState.swift
//  FireStream
//
//  Created by Pepe Becker on 1/29/20.
//

public class TypingState: Sendable {

    public required init() {
        super.init()
        self.type = SendableType.TypingState
    }

    public convenience init(_ type: TypingStateType) {
        self.init()
        self.setBodyType(type)
    }

    public func getTypingStateType() -> TypingStateType {
        return TypingStateType(super.getBodyType())
    }

    public static func fromSendable(_ sendable: Sendable) -> TypingState {
        return super.fromSendable(sendable)
    }

}
