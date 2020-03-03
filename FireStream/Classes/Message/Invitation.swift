//
//  Invitation.swift
//  FireStream
//
//  Created by Pepe Becker on 1/29/20.
//

import RxSwift

public class Invitation: Sendable {

    public static let ChatId = "id"

    public required init() {
        super.init()
        self.type = SendableType.Invitation
    }

    public convenience init(_ type: InvitationType, _ chatId: String) {
        self.init()
        super.setBodyType(type)
        self.body?[Self.ChatId] = chatId
    }

    public override func getBodyType() -> InvitationType {
        return InvitationType(super.getBodyType())
    }

    public func getChatId() throws -> String {
        return try! getBodyString(Self.ChatId)
    }

    public func accept() -> Completable {
        if getBodyType().equals(InvitationType.chat()) {
            do {
                return Fire.stream().joinChat(Chat(try getChatId()))
            } catch {
                return Completable.error(error)
            }
        }
        return Completable.empty()
    }

    public class func fromSendable(_ sendable: Sendable) -> Invitation {
        return super.fromSendable(sendable)
    }

}
