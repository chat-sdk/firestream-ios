//
//  RxFirestore.swift
//  FireStream
//
//  Created by Pepe Becker on 2/10/20.
//

import RxSwift
import FirebaseFirestore

public class RxFirestore {

    internal var lr: ListenerRegistration?

    public func on(_ ref: DocumentReference) -> Observable<DocumentSnapshot> {
        return Observable.create { emitter in
            self.lr = ref.addSnapshotListener({ (snapshot, error) in
                if let error = error {
                    emitter.onError(error)
                } else if let snapshot = snapshot {
                    emitter.onNext(snapshot)
                }
            })
            return Disposables.create(with: self.dispose)
        }
    }

    public func on(_ ref: Query) -> Observable<DocumentChange> {
        return Observable.create { emitter in
            self.lr = ref.addSnapshotListener({ (snapshot, error) in
                if let error = error {
                    emitter.onError(error)
                } else if let snapshot = snapshot {
                    for dc in snapshot.documentChanges {
                        emitter.onNext(dc)
                    }
                }
            })
            return Disposables.create()
        }
    }

    public func add(_ ref: CollectionReference, _ data: [String : Any]) -> Single<String> {
        return add(ref, data, nil);
    }

    public func add(_ ref: CollectionReference, _ data: [String : Any], _ newId: Consumer<String>?) -> Single<String> {
        return Single.create { emitter in
            let docRef = ref.document()
            if let newId = newId {
                newId(docRef.documentID)
            }
            docRef.setData(data) { error in
                if let error = error {
                    emitter(.error(error))
                } else {
                    emitter(.success(docRef.documentID))
                }
            }
            return Disposables.create()
        }
    }

    public func delete(_ ref: DocumentReference) -> Completable {
        return Completable.create { emitter in
            ref.delete { error in
                if let error = error {
                    emitter(.error(error))
                } else {
                    emitter(.completed)
                }
            }
            return Disposables.create()
        }
    }

    public func set(_ ref: DocumentReference, _ data: [String: Any]) -> Completable {
        return Completable.create { emitter in
            ref.setData(data) { error in
                if let error = error {
                    emitter(.error(error))
                } else {
                    emitter(.completed)
                }
            }
            return Disposables.create()
        }
    }

    public func update(_ ref: DocumentReference, _ data: [AnyHashable: Any]) -> Completable {
        return Completable.create { emitter in
            ref.updateData(data) { error in
                if let error = error {
                    emitter(.error(error))
                } else {
                    emitter(.completed)
                }
            }
            return Disposables.create()
        }
    }

    public func get(_ ref: Query) -> Single<Optional<QuerySnapshot>> {
        return Single.create { emitter -> Disposable in
            ref.getDocuments { (snapsot, error) in
                if let error = error {
                    emitter(.error(error))
                } else if let snapsot = snapsot, !snapsot.isEmpty {
                    emitter(.success(snapsot))
                }
            }
            return Disposables.create()
        }
    }

    public func get(_ ref: DocumentReference) -> Single<Optional<DocumentSnapshot>> {
        return Single.create { emitter -> Disposable in
            ref.addSnapshotListener { (snapsot, error) in
                if let error = error {
                    emitter(.error(error))
                } else if let snapsot = snapsot, snapsot.exists && snapsot.data() != nil {
                    emitter(.success(snapsot))
                }
            }
            return Disposables.create()
        }
    }

    public func dispose() {
        lr?.remove()
    }

}
