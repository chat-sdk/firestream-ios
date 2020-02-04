//
//  Meta.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

import Foundation

public class Meta {

    internal var name = ""
    internal var imageURL = ""
    internal var created: Date?
    internal var data: [String: Any]?
    internal var timestamp: Any?
    internal var wrapped = false

    public convenience init(name: String, imageURL: String) {
        self.init(name: name, imageURL: imageURL, data: nil)
    }

    public convenience init(name: String, imageURL: String, data: [String: Any]?) {
        self.init(name: name, imageURL: imageURL, created: nil, data: data)
    }

    public init(name: String, imageURL: String, created: Date?, data: [String: Any]?) {
        self.name = name
        self.imageURL = imageURL
        self.created = created
        self.data = data
    }

    public func getName() -> String {
        return self.name
    }

    public func setName(name: String) -> Meta {
        self.name = name
        return self
    }

    public func getImageURL() -> String {
        return self.imageURL
    }

    public func setImageURL(imageURL: String) -> Meta{
        self.imageURL = imageURL
        return self
    }

    public func setData(data: [String: Any]?) -> Meta {
        self.data = data
        return self
    }

    public func getData() -> [String: Any]? {
        return self.data
    }

    public func addTimestamp() -> Meta {
        // MARK: TODO
        // self.timestamp = Fire.privateApi().getFirebaseService().core.timestamp()
        return self
    }

    public func wrap() -> Meta {
        self.wrapped = true
        return self
    }

    public func getCreated() -> Date? {
        return self.created
    }

    public func setCreated(created: Date?) -> Meta {
        self.created = created
        return self
    }

    public static func nameData(name: String) -> [String: Any] {
        return [Keys.Name: name]
    }

    public static func imageURLData(imageURL: String) -> [String: Any] {
        return [Keys.ImageURL: imageURL]
    }

    public static func dataData(data: [String: Any]) -> [String: Any] {
        return [Keys.Data: data]
    }

    public func toData() -> [String: Any] {
        var data = [String: Any]()

        data[Keys.Name] = self.name
        data[Keys.ImageURL] = self.imageURL
        if (self.data != nil) {
            data[Keys.Data] = self.data
        }
        if (timestamp != nil) {
            data[Keys.Created] = self.timestamp
        }
        if (self.wrapped) {
            return Self.wrap(data)
        }
        return data
    }

    internal static func wrap(_ map: [String: Any]) -> [String: Any] {
        return [Keys.Meta: map]
    }

    public func copy() -> Meta {
        let meta = Meta(name: self.name, imageURL: self.imageURL)
        meta.created = created
        meta.data = data
        return meta
    }

    public static func from(name: String, imageURL: String) -> Meta {
        return Meta(name: name, imageURL: imageURL)
    }

    public static func from(name: String, imageURL: String, data: [String: Any]) -> Meta {
        return Meta(name: name, imageURL: imageURL, data: data)
    }


}

