//
//  Path.swift
//  FireStream
//
//  Created by Pepe Becker on 2/4/20.
//

public class Path {

    internal var components = [String]()

    /**
     * The remainder type used to fix an issue which arises with Firestore. In Firestore
     * there are documents and collections. But sometimes we want to reference information
     * that type at a path within a document for example:
     * chats/id/meta
     * Here the id, type a document but if we generated a path from self, it would point to a
     * collection. Therefore if the path we pass in to the ref doesn't point to the correct
     * reference type, we truncate it by one and set the remainder
     */
    internal var remainder: String?

    public init(_ path: [String]) {
        for s in path {
            components.append(s)
        }
    }

    public convenience init(_ path: String) {
        self.init(path.split(separator: "/").map { "\($0)" })
    }

    public convenience init(_ path: String...) {
        self.init(path)
    }

    public func first() -> String {
        return self.components[0]
    }

    public func last() -> String {
        return self.components[size()-1]
    }

    public func size() -> Int {
        return self.components.count
    }

    public func get(_ index: Int) -> String? {
        if size() > index {
            return components[index]
        }
        return nil
    }

    public func toString() -> String {
        return components.joined(separator: "/")
    }

    public func child(_ child: String) -> Path {
        self.components.append(child)
        return self
    }

    public func children(_ children: String...) -> Path {
        self.components.append(contentsOf: children)
        return self
    }

    public func removeLast() -> Path {
        if size() > 0 {
            self.components.remove(at: size() - 1)
        }
        return self
    }

    public func isDocument() -> Bool {
        return size() % 2 == 0
    }

    public func getComponents() -> [String] {
        return self.components
    }

    public func getRemainder() -> String? {
        return self.remainder
    }

    public func normalizeForDocument() {
        if !isDocument() {
            remainder = last()
            _ = removeLast()
        }
    }

    public func normalizeForCollection() {
        if isDocument() {
            remainder = last()
            _ = removeLast()
        }
    }

    /**
     * For Firestore to update nested fields on a document, you need to use a
     * dot notation. This method returns the remainder if it exists plus a
     * dotted path component
     * @param component path to extend
     * @return dotted components
     */
    public func dotPath(_ component: String) -> String {
        if let remainder = self.remainder {
            return remainder + "." + component
        } else {
            return component
        }
    }

}
