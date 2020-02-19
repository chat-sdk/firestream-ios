//
//  Paths.swift
//  FireStream
//
//  Created by Pepe Becker on 2/4/20.
//

public class Paths: Keys {

    public static func root() -> Path? {
        if let config = Fire.internalApi().getConfig() {
            return Path(config.getRoot(), config.getSandbox())
        } else {
            return nil
        }
    }

    public static func usersPath() -> Path? {
        return root()?.child(Users)
    }

    public static func userPath(_ uid: String) -> Path? {
        return usersPath()?.child(uid)
    }

    public static func userPath() -> Path? {
        if let userId = currentUserId() {
            return userPath(userId)
        }
        return nil
    }

    public static func messagesPath(_ uid: String) -> Path? {
        return userPath(uid)?.child(Messages)
    }

    public static func messagesPath() -> Path? {
        if let userId = currentUserId() {
            return messagesPath(userId)
        }
        return nil
    }

    public static func userChatsPath() -> Path? {
        if let userId = currentUserId() {
            return userPath(userId)?.child(Keys.Chats)
        }
        return nil
    }

    public static func userMutedPath() -> Path? {
        if let userId = currentUserId() {
            return userPath(userId)?.child(Keys.Muted)
        }
        return nil
    }

    public static func userGroupChatPath(_ chatId: String) -> Path? {
        return userChatsPath()?.child(chatId)
    }

    public static func messagePath(_ messageId: String) -> Path? {
        if let userId = currentUserId() {
            return messagePath(userId, messageId)
        }
        return nil
    }

    public static func messagePath(_ uid: String, _ messageId: String) -> Path? {
        return messagesPath(uid)?.child(messageId)
    }

    internal static func currentUserId() -> String? {
        return Fire.stream().currentUserId()
    }

    public static func contactsPath() -> Path? {
        return userPath()?.child(Contacts)
    }

    public static func blockedPath() -> Path? {
        return userPath()?.child(Blocked)
    }

    public static func chatsPath() -> Path? {
        return root()?.child(Chats)
    }

    public static func chatPath(_ chatId: String) -> Path? {
        return chatsPath()?.child(chatId)
    }

    public static func chatMetaPath(_ chatId: String) -> Path? {
        return chatsPath()?.child(chatId).child(Meta)
    }

    public static func chatMessagesPath(_ chatId: String) -> Path? {
        return chatPath(chatId)?.child(Messages)
    }

    public static func chatUsersPath(_ chatId: String) -> Path? {
        return chatPath(chatId)?.child(Users)
    }

}
