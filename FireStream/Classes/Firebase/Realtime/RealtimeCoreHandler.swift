//
//  RealtimeCoreHandler.swift
//  FireStrem
//
//  Created by Pepe Becker on 3/6/20.
//

import RxSwift
import FirebaseDatabase

class RealtimeCoreHandler: FirebaseCoreHandler {

    public override func listChangeOn(_ path: Path) -> Observable<FireStreamEvent<ListData>> {
        return RxRealtime().childOn(RefRealtime.get(path)).flatMap { change -> Maybe<FireStreamEvent<ListData>> in
            let snapshot = change.snapshot
            if let data = snapshot.value as? [String: Any], let type = change.type {
                return Maybe.just(FireStreamEvent(ListData(change.snapshot.key, data), type))
            }
            return Maybe.empty()
        }
    }

    public override func deleteSendable(_ messagesPath: Path) -> Completable {
        return RxRealtime().delete(RefRealtime.get(messagesPath))
    }

    public override func send(_ messagesPath: Path, _ sendable: Sendable, _ newId: Consumer<String>?) -> Completable {
        return RxRealtime().add(RefRealtime.get(messagesPath), sendable.toData(), timestamp(), newId).asCompletable()
    }

    public override func addUsers(_ path: Path, _ dataProvider: FireStreamUser.DataProvider, _ users: [FireStreamUser]) -> Completable {
        return addBatch(path, idsForUsers(users), dataForUsers(users, dataProvider))
    }

    public override func removeUsers(_ path: Path, _ users: [FireStreamUser]) -> Completable {
        return removeBatch(path, idsForUsers(users))
    }

    public override func updateUsers(_ path: Path, _ dataProvider: FireStreamUser.DataProvider, _ users: [FireStreamUser]) -> Completable {
        return updateBatch(path, idsForUsers(users), dataForUsers(users, dataProvider))
    }

    public override func loadMoreMessages(_ messagesPath: Path, _ fromDate: Date?, _ toDate: Date?, _ limit: Int?) -> Single<[Sendable]> {
        return Single.create { emitter in
            var query = RefRealtime.get(messagesPath) as DatabaseQuery
            query = query.queryOrdered(byChild: Keys.Date)

            if let fromDate = fromDate {
                query = query.queryStarting(atValue: fromDate.timeIntervalSince1970, childKey: Keys.Date)
            }

            if let toDate = toDate {
                query = query.queryEnding(atValue: toDate.timeIntervalSince1970, childKey: Keys.Date)
            }

            if let limit = limit {
                if fromDate != nil {
                    query = query.queryLimited(toFirst: UInt(limit))
                }
                if toDate != nil {
                    query = query.queryLimited(toLast: UInt(limit))
                }
            }

            emitter(.success(query))
            return Disposables.create()
        }.flatMap { RxRealtime().get($0) }.map { snapshot in
            var sendables = [Sendable]()
            if let snapshot = snapshot {
                if snapshot.exists() {
                    let enumerator = snapshot.children
                    while let child = enumerator.nextObject() as? DataSnapshot {
                        sendables.append(self.sendableFromSnapshot(child))
                    }
                }
            }
            return sendables
        }
    }

    public override func dateOfLastSentMessage(_ messagesPath: Path) -> Single<Date> {
        return Single.create { emitter in
            var query = RefRealtime.get(messagesPath) as DatabaseQuery

            query = query.queryEqual(toValue: Fire.stream().currentUserId())
            query = query.queryOrdered(byChild: Keys.From)
            query = query.queryLimited(toLast: 1)

            emitter(.success(query))
            return Disposables.create()
        }.flatMap { RxRealtime().get($0) }.map { snapshot in
            if let snapshot = snapshot {
                if let date = self.sendableFromSnapshot(snapshot).getDate() {
                    return date
                }
            }
            return Date(timeIntervalSince1970: 0)
        }
    }

    public func sendableFromSnapshot(_ snapshot: DataSnapshot) -> Sendable {
        let sendable = Sendable()
        sendable.setId(snapshot.key)

        if snapshot.hasChild(Keys.From), let from = snapshot.childSnapshot(forPath: Keys.From).value as? String {
            sendable.setFrom(from)
        }
        if snapshot.hasChild(Keys.Date), let timestamp = snapshot.childSnapshot(forPath: Keys.Date).value as? Double {
            sendable.setDate(Date(timeIntervalSince1970: timestamp))
        } else {
            print("Coult not set data")
        }
        if snapshot.hasChild(Keys.type), let type = snapshot.childSnapshot(forPath: Keys.type).value as? String {
            sendable.setType(type)
        }
        if snapshot.hasChild(Keys.Body), let body = snapshot.childSnapshot(forPath: Keys.Body).value as? [String: Any] {
            sendable.setBody(body)
        }
        return sendable
    }

    public override func messagesOn(_ messagesPath: Path, _ newerThan: Date?, _ limit: Int?) -> Observable<FireStreamEvent<Sendable>> {
        return Single<DatabaseQuery>.create { emitter in
            var query = RefRealtime.get(messagesPath) as DatabaseQuery

            query = query.queryOrdered(byChild: Keys.Date)
            if let newerThan = newerThan {
                query = query.queryStarting(atValue: newerThan.timeIntervalSince1970, childKey: Keys.Date)
            }
            if let limit = limit {
                query = query.queryLimited(toLast: UInt(limit))
            }
            emitter(.success(query))
            return Disposables.create()
        }.asObservable().flatMap { RxRealtime().childOn($0) }.flatMap { change -> Maybe<FireStreamEvent<Sendable>> in
            let sendable = self.sendableFromSnapshot(change.snapshot)
            if let type = change.type {
                return Maybe.just(FireStreamEvent(sendable, type))
            }
            return Maybe.empty()
        }
    }

    public override func timestamp() -> Any {
        return ServerValue.timestamp()
    }

    internal func removeBatch(_ path: Path, _ keys: [String]) -> Completable {
        return updateBatch(path, keys, nil)
    }

    internal func addBatch(_ path: Path, _ keys: [String], _ values: [[String: Any]]?) -> Completable {
        return updateBatch(path, keys, values)
    }

    internal func updateBatch(_ path: Path, _ keys: [String], _ values: [[String: Any]]?) -> Completable {
        return Completable.create { emitter in
            var data = [String: Any]()

            for i in 0..<keys.count {
                let key = keys[i]
                let value = values != nil ? values?[i] : nil
                data[path.toString() + "/" + key] = value ?? NSNull()
            }

            RefRealtime.db().reference().updateChildValues(data) { (error, databaseRef) in
                if let error = error {
                    emitter(.error(error))
                } else {
                    emitter(.completed)
                }
            }

            return Disposables.create()
        }
    }

    internal func idsForUsers(_ users: [FireStreamUser]) -> [String] {
        return users.map { $0.getId() }
    }

    internal func dataForUsers(_ users: [FireStreamUser], _ provider: FireStreamUser.DataProvider) -> [[String: Any]] {
        return users.map { provider.data($0) }
    }

    public override func mute(_ path: Path, _ data: [String: Any]) -> Completable {
        return RxRealtime().set(RefRealtime.get(path), data)
    }

    public override func unmute(_ path: Path) -> Completable {
        return RxRealtime().delete(RefRealtime.get(path))
    }

}
