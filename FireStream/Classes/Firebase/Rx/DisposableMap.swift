//
//  DisposableMap.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

import RxSwift

public class DisposableMap {

    internal class DisposableList {
        private var disposables = [Disposable]()

        public func add(_ disposable: Disposable) {
            self.disposables.append(disposable)
        }

        // TODO: is this required?
        // public func remove(_ disposable: Disposable) {
        //     self.disposables.removeAll { d in
        //         return d == disposable
        //     }
        // }

        public func dispose() {
            for disposable in self.disposables {
                disposable.dispose()
            }
            self.disposables.removeAll()
        }

    }

    internal static let DefaultKey = "def"

    internal var map = [String: DisposableList]()

    public init() {

    }

    public func put(_ key: String, _ disposable: Disposable) {
        get(key).add(disposable)
    }

    public func dispose(_ key: String) {
        get(key).dispose()
    }

    internal func get(_ key: String) -> DisposableList {
        if let list = map[key] {
            return list
        }
        let list = DisposableList()
        self.map[key] = list
        return list
    }

    public func add(_ disposable: Disposable) {
        get(Self.DefaultKey).add(disposable)
    }

    public func dispose() {
        get(Self.DefaultKey).dispose()
    }

    public func disposeAll() {
        for key in map.keys {
            get(key).dispose()
        }
    }

}
