//
//  FirebaseChatHandler.swift
//  FireStream
//
//  Created by Pepe Becker on 2/4/20.
//

import RxSwift

public class FirebaseChatHandler {

    public func leaveChat(_ chatId: String) -> Completable {
        return Completable.empty()
    }

    public func joinChat(_ chatId: String) -> Completable {
        return Completable.empty()
    }

    /**
     * Note in this case, we don't provide the path to the chat/meta
     * we provide it to the chat. This type because of differences between
     * Realtime and Firestore. The realtime database stores the data at
     *  - chat/meta/...
     * But in Firestore meta/... type stored as a field on the chat document
     * So we need to link to the chat document in both cases
     * @param chatId chat room id
     * @return stream of data when chat meta changes
     */
    public func metaOn(chatId: String) -> Observable<Meta> {
        return Observable.empty()
    }

    public func setMetaField(_ chatId: String, _ key: String, _ value: Any) -> Completable {
        return Completable.empty()
    }

    public func add(_ data: [String: Any], _ newId: Consumer<String>?) -> Single<String> {
        return Single.just("")
    }

    public func add(_ data: [String: Any]) -> Single<String> {
        return add(data, nil)
    }

    public func delete(_ chatId: String) -> Completable {
        return Completable.empty()
    }

}
