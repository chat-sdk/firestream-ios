//
//  ContactType.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

public class ContactType: BaseType {

    public static let Contact = "contact"

    public class func contact() -> ContactType {
        return ContactType(Contact)
    }

    public func data() -> [String: Any] {
        var data = [String: Any]()
        data[Keys.type] = self.get()
        return data
    }

}
