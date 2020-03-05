//
//  RxRealtime.swift
//  FireStream
//
//  Created by Pepe Becker on 3/5/20.
//

import RxSwift
import FirebaseDatabase

class RxRealtime: NSObject {

    public class DocumentChange {
        let snapshot: DataSnapshot
        let type: EventType?

        public init(_ snapshot: DataSnapshot) {
            self.snapshot = snapshot
            self.type = nil
        }

        public init(_ snapshot: DataSnapshot, _ type: EventType) {
            self.snapshot = snapshot
            self.type = type
        }
    }

    public func on(_ ref: DatabaseQuery) -> Observable<DocumentChange> {
        return Observable.create { emitter in
            let o = ref.observe(.childChanged, with: { snapshot in
                if snapshot.exists() && snapshot.value != nil {
                    emitter.onNext(DocumentChange(snapshot))
                }
            }, withCancel: emitter.onError)
            return Disposables.create { ref.removeObserver(withHandle: o) }
        }
    }

    public func childOn(_ ref: DatabaseQuery) -> Observable<DocumentChange> {
        return Observable.create { emitter in
            let o1 = ref.observe(.childAdded, with: { snapshot in
                emitter.onNext(DocumentChange(snapshot, EventType.Added))
            }, withCancel: emitter.onError)
            let o2 = ref.observe(.childAdded, with: { snapshot in
                emitter.onNext(DocumentChange(snapshot, EventType.Removed))
            }, withCancel: emitter.onError)
            let o3 = ref.observe(.childAdded, with: { snapshot in
                emitter.onNext(DocumentChange(snapshot, EventType.Modified))
            }, withCancel: emitter.onError)
            return Disposables.create {
                ref.removeObserver(withHandle: o1)
                ref.removeObserver(withHandle: o2)
                ref.removeObserver(withHandle: o3)
            }
        }
    }

    public func add(_ ref: DatabaseReference, _ data: Any) -> Single<String> {
        return add(ref, data, nil)
    }

    public func add(_ ref: DatabaseReference, _ data: Any, _ priority: Any?) -> Single<String> {
        return add(ref, data, priority, nil)
    }

    public func add(_ ref: DatabaseReference, _ data: Any, _ priority: Any?, _ newId: Consumer<String>?) -> Single<String> {
        return Single.create { emitter in
            let childRef = ref.childByAutoId()
            guard let id = childRef.key else {
                emitter(.error(FireStreamError("childRef.key returned nil")))
                return Disposables.create()
            }
            if let newId = newId {
                newId(id)
            }
            childRef.setValue(data, andPriority: priority) { (error, databaseRef) in
                if let error = error {
                    emitter(.error(error))
                } else {
                    emitter(.success(id))
                }
            }
            return Disposables.create()
        }
    }

    public func delete(_ ref: DatabaseReference) -> Completable {
        return Completable.create { emitter in
            ref.removeValue { (error, databaseRef) in
                if let error = error {
                    emitter(.error(error))
                } else {
                    emitter(.completed)
                }
            }
            return Disposables.create()
        }
    }

    public func set(_ ref: DatabaseReference, _ data: Any) -> Completable {
        return Completable.create { emitter in
            ref.setValue(data) { (error, databaseRef) in
                if let error = error {
                    emitter(.error(error))
                } else {
                    emitter(.completed)
                }
            }
            return Disposables.create()
        }
    }

    public func update(_ ref: DatabaseReference, _ data: [String: Any]) -> Completable {
        return Completable.create { emitter in
            ref.updateChildValues(data) { (error, databaseRef) in
                if let error = error {
                    emitter(.error(error))
                } else {
                    emitter(.completed)
                }
            }
            return Disposables.create()
        }
    }

    public func get(_ ref: DatabaseQuery) -> Single<DataSnapshot?> {
        ref.keepSynced(true)
        return Single.create { emitter in
            ref.observeSingleEvent(of: .childChanged, with: { snapshot in
                if snapshot.exists() && snapshot.value != nil {
                    emitter(.success(snapshot))
                } else {
                    emitter(.success(nil))
                }
            }, withCancel: { emitter(.error($0)) })
            return Disposables.create()
        }
    }

}
