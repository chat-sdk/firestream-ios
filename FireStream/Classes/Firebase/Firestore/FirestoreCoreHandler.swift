//
//  FirestoreCoreHandler.swift
//  FireStream
//
//  Created by Pepe Becker on 2/10/20.
//

import RxSwift
import FirebaseFirestore

public class FirestoreCoreHandler: FirebaseCoreHandler {

    public override func listChangeOn(_ path: Path) -> Observable<FireStreamEvent<ListData>> {
        do {
            let ref = try Ref.collection(path)
            return RxFirestore().on(ref).flatMap { change -> Maybe<FireStreamEvent<ListData>> in
                let d = change.document
                if d.exists {
                    let payload = ListData(d.documentID, d.data(with: .estimate))
                    return Maybe.just(FireStreamEvent(payload, Self.typeForDocumentChange(change)))
                }
                return Maybe.empty()
            }
        } catch {
            return Observable.error(error)
        }
    }

    public override func deleteSendable(_ messagesPath: Path) -> Completable {
        do {
            let ref = try Ref.document(messagesPath)
            return RxFirestore().delete(ref)
        } catch {
            return Completable.error(error)
        }
    }

    public override func send(_ messagesPath: Path, _ sendable: Sendable, _ newId: Consumer<String>?) -> Completable {
        do {
            let ref = try Ref.collection(messagesPath)
            return RxFirestore().add(ref, sendable.toData(), newId).asCompletable()
        } catch {
            return Completable.error(error)
        }
    }

    public override func addUsers(_ path: Path, _ dataProvider: FireStreamUser.DataProvider, _ users: [FireStreamUser]) -> Completable {
        return Single.create { emitter in
            do {
                let ref = try Ref.collection(path)
                let batch = Ref.db().batch()

                for u in users {
                    let docRef = ref.document(u.getId())
                    batch.setData(dataProvider.data(u), forDocument: docRef)
                }
                emitter(.success(batch))
            } catch {
                emitter(.error(error))
            }
            return Disposables.create()
        }.flatMapCompletable(self.runBatch)
    }

    public override func updateUsers(_ path: Path, _ dataProvider: FireStreamUser.DataProvider, _ users: [FireStreamUser]) -> Completable {
        return Single.create { emitter in
            do {
                let ref = try Ref.collection(path)
                let batch = Ref.db().batch()

                for u in users {
                    let docRef = ref.document(u.getId())
                    batch.updateData(dataProvider.data(u), forDocument: docRef)
                }
                emitter(.success(batch))
            } catch {
                emitter(.error(error))
            }
            return Disposables.create()
        }.flatMapCompletable(self.runBatch)
    }

    public override func removeUsers(_ path: Path, _ users: [FireStreamUser]) -> Completable {
        return Single.create { emitter in
            do {
                let ref = try Ref.collection(path)
                let batch = Ref.db().batch()

                for u in users {
                    let docRef = ref.document(u.getId())
                    batch.deleteDocument(docRef)
                }
                emitter(.success(batch))
            } catch {
                emitter(.error(error))
            }
            return Disposables.create()
        }.flatMapCompletable(self.runBatch)
    }

    public override func loadMoreMessages(_ messagesPath: Path, _ fromDate: Date?, _ toDate: Date?, _ limit: Int?) -> Single<[Sendable]> {
        return Single<Query>.create { emitter in
            do {
                var query = try Ref.collection(messagesPath) as Query

                query = query.order(by: Keys.Data, descending: false)
                if let fromDate = fromDate {
                    query = query.whereField(Keys.Date, isGreaterThan: fromDate)
                }
                if let toDate = toDate {
                    query = query.whereField(Keys.Date, isLessThanOrEqualTo: toDate)
                }

                if let limit = limit {
                    if fromDate != nil {
                        query = query.limit(to: limit)
                    }
                    if toDate != nil {
                        query = query.limit(to: limit)
                        // TODO: fix this
//                        query = query.limitToLast(limit)
                    }
                }

                emitter(.success(query))
            } catch {
                emitter(.error(error))
            }
            return Disposables.create()
        }.flatMap { RxFirestore().get($0) }.map { querySnapshot in
            var sendables = [Sendable]()
            if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                for c in querySnapshot.documentChanges {
                    let docSnapshot = c.document
                    // Add the message
                    if docSnapshot.exists && c.type == .added {
                        let sendable = self.sendableFromSnapshot(docSnapshot)
                        sendables.append(sendable)
                    }
                }
            }
            return sendables
        }
    }

    public override func dateOfLastSentMessage(_ messagesPath: Path) -> Single<Date> {
        return Single<Query>.create { emitter in
            do {
                if let userId = Fire.stream().currentUserId() {
                    var query = try Ref.collection(messagesPath) as Query
                    query = query.whereField(Keys.From, isEqualTo: userId)
                    query = query.order(by: Keys.Date, descending: true)
                    query = query.limit(to: 1)
                    emitter(.success(query))
                } else {
                    emitter(.error(FireStreamError("userId is nil")))
                }
            } catch {
                emitter(.error(error))
            }
            return Disposables.create()
        }.flatMap { RxFirestore().get($0) }.map { querySnapshot -> Date in
            if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                if querySnapshot.documentChanges.count > 0 {
                    if let change = querySnapshot.documentChanges.first, change.document.exists {
                        let sendable = self.sendableFromSnapshot(change.document)
                        sendable.setBody(change.document.data())
                        if let date = sendable.getDate() {
                            return date
                        }
                    }
                }
            }
            return Date(timeIntervalSince1970: 0)
        }
    }

    /**
     * Start listening to the current message reference and pass the messages to the events
     * @param newerThan only listen for messages after this date
     * @return a events of message results
     */
    public func messagesOn(_ messagesPath: Path, _ newerThan: Date, limit: Int) -> Observable<FireStreamEvent<Sendable>> {
        return Single<Query>.create { emitter in
            do {
                var query = try Ref.collection(messagesPath) as Query

                query = query.order(by: Keys.Date, descending: false)
                query = query.whereField(Keys.Date, isGreaterThan: newerThan)
                query.limit(to: limit)

                emitter(.success(query))
            } catch {
                emitter(.error(error))
            }
            return Disposables.create()
        }.asObservable().flatMap { query -> Observable<FireStreamEvent<Sendable>> in
            return RxFirestore().on(query).flatMap { docChange -> Maybe<FireStreamEvent<Sendable>> in
                let docSnapshot = docChange.document
                if docSnapshot.exists {
                    let sendable = self.sendableFromSnapshot(docSnapshot)
                    return Maybe.just(FireStreamEvent(sendable, Self.typeForDocumentChange(docChange)))
                }
                return Maybe.empty()
            }
        }
    }

    public override func timestamp() -> Any {
        return FieldValue.serverTimestamp()
    }

    /**
     * Firestore helper methods
     */

    internal func sendableFromSnapshot(_ snapshot: DocumentSnapshot) -> Sendable {
        let sendable = Sendable()
        sendable.setId(snapshot.documentID)
        if let from = snapshot.get(Keys.From) as? String {
            sendable.setFrom(from)
        }
        if let timestamp = snapshot.get(Keys.Date, serverTimestampBehavior: .estimate) as? Date {
            sendable.setDate(timestamp)
        }
        if let body = snapshot.get(Keys.Body) as? [String: Any] {
            sendable.setBody(body)
        }
        if let type = snapshot.get(Keys.type) as? String {
            sendable.setType(type)
        }
        return sendable
    }

    /**
     * Run a Firestore updateBatch operation
     * @param batch Firestore updateBatch
     * @return completion
     */
    internal func runBatch(_ batch: WriteBatch) -> Completable {
        return Completable.create { emitter in
            batch.commit(completion: { error in
                if let error = error {
                    emitter(.error(error))
                } else {
                    emitter(.completed)
                }
            })
            return Disposables.create()
        }
    }

    public class func typeForDocumentChange(_ change: DocumentChange) -> EventType {
        switch change.type {
        case .added:
            return EventType.Added
        case .removed:
            return EventType.Removed
        case .modified:
            return EventType.Modified
        default:
            return EventType.None
        }
    }

    public override func mute(_ path: Path, _ data: [String: Any]) -> Completable {
        do {
            let ref = try Ref.document(path)
            return RxFirestore().set(ref, data)
        } catch {
            return Completable.error(error)
        }
    }

    public override func unmute(_ path: Path) -> Completable {
        do {
            let ref = try Ref.document(path)
            return RxFirestore().delete(ref)
        } catch {
            return Completable.error(error)
        }
    }

}
