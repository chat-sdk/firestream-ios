//
//  Ref.swift
//  FireStream
//
//  Created by Pepe Becker on 2/10/20.
//

import FirebaseFirestore

public class Ref {

    public class func collection(_ path: Path?) throws -> CollectionReference {
        guard let path = path else {
            throw FireStreamError("path is nil")
        }
        let ref = referenceFromPath(path)
        if ref.isKind(of: CollectionReference.self) {
            return ref as! CollectionReference
        } else {
            throw FireStreamError("CollectionReference expected but path points to document: \(path.toString())")
        }
    }

    public class func document(_ path: Path?) throws -> DocumentReference {
        guard let path = path else {
            throw FireStreamError("path is nil")
        }
        let ref = referenceFromPath(path)
        if ref.isKind(of: DocumentReference.self) {
            return ref as! DocumentReference
        } else {
            throw FireStreamError("DocumentReference expected but path points to collection: \(path.toString())")
        }
    }

    public class func referenceFromPath(_ path: Path) -> NSObject {
        var ref = db().collection(path.first()) as NSObject

        for i in 1..<path.size() {
            guard let component = path.get(i) else {
                continue
            }

            if ref.isKind(of: DocumentReference.self) {
                ref = (ref as! DocumentReference).collection(component)
            } else {
                ref = (ref as! CollectionReference).document(component)
            }
        }
        return ref
    }

    public class func db() -> Firestore {
        // TODO: make sure this references a shared firebase app
        return Firestore.firestore()
    }

}
