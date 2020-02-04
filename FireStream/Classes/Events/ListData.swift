//
//  ListData.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

public class ListData {

    internal let id: String
    internal let data: [String: Any]

    public init(id: String, data: [String: Any]) {
        self.id = id
        self.data = data
    }

    public func get(key: String) -> Any? {
        // MARK: TODO
        // if let data = self.data {
            return data[key]
        // }
        // return nil
    }

    public func getId() -> String {
        return self.id
    }

    public func getData() -> [String: Any] {
        return self.data
    }

}
