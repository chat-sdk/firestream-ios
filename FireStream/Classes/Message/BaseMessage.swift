//
//  BaseMessage.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

import Foundation

public class BaseMessage {

    internal var from: String?
    internal var date: Date? = Date()
    internal var body: [String: Any]? = [:]
    internal var type: String?

    public func getFrom() -> String? {
        return self.from
    }

    public func setFrom(_ from: String?) {
        self.from = from
    }

    public func getDate() -> Date? {
        return self.date
    }

    public func setDate(_ date: Date?) {
        self.date = date
    }

    public func getBody() -> [String: Any]? {
        return body
    }

    public func setBody(_ body: [String: Any]?) {
        self.body = body
    }

    public func getType() -> String? {
        return type
    }

    public func setType(_ type: String?) {
        self.type = type
    }

    public func isType(_ type: SendableType?) -> Bool {
        return getType() == type?.get()
    }

}
