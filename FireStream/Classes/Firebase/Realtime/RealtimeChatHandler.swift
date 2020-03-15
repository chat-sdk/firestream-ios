//
//  RealtimeChatHandler.swift
//  FireStream
//
//  Created by Pepe Becker on 3/5/20.
//

import RxSwift
import FirebaseDatabase

public class RealtimeChatHandler: FirebaseChatHandler {

    public override func leaveChat(_ chatId: String) -> Completable {
        guard let path = Paths.userGroupChatPath(chatId) else {
            return Completable.error(FireStreamError("path is nil"))
        }
        return RxRealtime().delete(RefRealtime.get(path))
    }

    public override func joinChat(_ chatId: String) -> Completable {
        guard let path = Paths.userGroupChatPath(chatId) else {
            return Completable.error(FireStreamError("path is nil"))
        }
        return RxRealtime().set(RefRealtime.get(path), FireStreamUser.dateDataProvider().data(nil))
    }

    public override func setMetaField(_ chatId: String, _ key: String, _ value: Any) -> Completable {
        guard let path = Paths.chatMetaPath(chatId)?.child(key) else {
            return Completable.error(FireStreamError("path is nil"))
        }
        return RxRealtime().set(RefRealtime.get(path), value)
    }

    public override func metaOn(_ chatId: String) -> Observable<Meta> {
        guard let path = Paths.chatPath(chatId) else {
            return Observable.error(FireStreamError("path is nil"))
        }
        return RxRealtime().on(RefRealtime.get(path)).flatMap { change -> Maybe<Meta> in
            var snapshot = change.snapshot
            if snapshot.hasChild(Keys.Meta) {
                snapshot = snapshot.childSnapshot(forPath: Keys.Meta)
                let meta = Meta()
                if snapshot.hasChild(Keys.Name), let name = snapshot.childSnapshot(forPath: Keys.Name).value as? String {
                    _ = meta.setName(name)
                }
                if snapshot.hasChild(Keys.Created), let time = snapshot.childSnapshot(forPath: Keys.Created).value as? TimeInterval {
                    _ = meta.setCreated(Date(timestamp: time))
                }
                if snapshot.hasChild(Keys.ImageURL), let imageURL = snapshot.childSnapshot(forPath: Keys.ImageURL).value as? String {
                    _ = meta.setImageURL(imageURL)
                }
                if snapshot.hasChild(Keys.Data), let data = snapshot.childSnapshot(forPath: Keys.Data).value as? [String: Any] {
                    _ = meta.setData(data)
                }
                return Maybe.just(meta)
            }
            return Maybe.empty()
        }.asObservable()
    }

    public override func add(_ data: [String : Any], _ newId: Consumer<String>?) -> Single<String> {
        guard let path = Paths.chatsPath() else {
            return Single.error(FireStreamError("path is nil"))
        }
        return RxRealtime().add(RefRealtime.get(path), data, newId)
    }

    public override func delete(_ chatId: String) -> Completable {
        guard let path = Paths.chatPath(chatId) else {
            return Completable.error(FireStreamError("path is nil"))
        }
        return RxRealtime().delete(RefRealtime.get(path))
    }

}
