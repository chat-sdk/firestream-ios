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

    public convenience init(type: InvitationType, chatId: String) {
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
                // MARK: TODO
                // return Fire.Stream.joinChat(new Chat(getChatId()));
            } catch {
                return Completable.error(error)
            }
        }
        return Completable.empty()
    }

    public static func fromSendable(_ sendable: Sendable) -> Invitation {
        return super.fromSendable(sendable)
    }

}
