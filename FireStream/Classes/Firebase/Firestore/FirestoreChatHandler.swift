//
//  FirestoreChatHandler.swift
//  FireStream
//
//  Created by Pepe Becker on 2/10/20.
//

import RxSwift
import FirebaseFirestore

public class FirestoreChatHandler: FirebaseChatHandler {

    public override func leaveChat(_ chatId: String) -> Completable {
        do {
            let ref = try Ref.document(Paths.userGroupChatPath(chatId))
            return RxFirestore().delete(ref)
        } catch {
            return Completable.error(error)
        }
    }

    public override func joinChat(_ chatId: String) -> Completable {
        do {
            let ref = try Ref.document(Paths.userGroupChatPath(chatId))
            return RxFirestore().set(ref, FireStreamUser.dateDataProvider().data(nil))
        } catch {
            return Completable.error(error)
        }
    }

    public override func setMetaField(_ chatId: String, _ key: String, _ value: Any) -> Completable {
        let chatMetaPath = Paths.chatMetaPath(chatId)
        chatMetaPath?.normalizeForDocument()

        do {
            let ref = try Ref.document(chatMetaPath)
            return RxFirestore().update(ref, [
                chatMetaPath?.dotPath(key): value
            ])
        } catch {
            return Completable.error(error)
        }
    }

    public override func metaOn(_ chatId: String) -> Observable<Meta> {
        do {
            let ref = try Ref.document(Paths.chatPath(chatId))
            return RxFirestore().on(ref).map { snapshot in
                let meta = Meta()

                let base = Keys.Meta + "."

                if let name = snapshot.get(base + Keys.Name) as? String {
                    _ = meta.setName(name)
                }
                if let date = snapshot.get(base + Keys.Created, serverTimestampBehavior: .estimate) as? Date {
                    _ = meta.setCreated(date)
                }
                if let imageURL = snapshot.get(base + Keys.ImageURL) as? String {
                    _ = meta.setImageURL(imageURL)
                }

                var data = [String: Any]()

                if let dataMap = snapshot.get(base + Keys.Data) as? [String: Any] {
                    for key in dataMap.keys {
                        data[key] = dataMap[key]
                    }
                }
                _ = meta.setData(data)

                return meta
            }
        } catch {
            return Observable.error(error)
        }
    }

    public override func add(_ data: [String: Any], _ newId: Consumer<String>?) -> Single<String> {
        do {
            let ref = try Ref.collection(Paths.chatsPath())
            return RxFirestore().add(ref, data, newId)
        } catch {
            return Single.error(error)
        }
    }

    public override func delete(_ chatId: String) -> Completable {
        do {
            let ref = try Ref.document(Paths.chatPath(chatId))
            return RxFirestore().delete(ref)
        } catch {
            return Completable.error(error)
        }
    }

}
