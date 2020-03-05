//
//  RefRealtime.swift
//  FireStream
//
//  Created by Pepe Becker on 3/4/20.
//

import FirebaseDatabase

public class RefRealtime {

    public class func get(_ path: Path) -> DatabaseReference {
        var ref = db().reference(withPath: path.first())
        for i in 1..<path.size() {
            if let part = path.get(i) {
                ref = ref.child(part)
            }
        }
        return ref
    }

    public class func db() -> Database {
        // TODO: make sure this references a shared firebase app
        return Database.database()
    }

}
