//
//  Paths.swift
//  FireStream
//
//  Created by Pepe Becker on 2/4/20.
//

public class Paths: Keys {

    public class func root() -> Path? {
        if let config = Fire.internalApi().getConfig() {
            return Path(config.getRoot(), config.getSandbox())
        } else {
            return nil
        }
    }

    public class func usersPath() -> Path? {
        return root()?.child(Users)
    }

    public class func userPath(_ uid: String) -> Path? {
        return usersPath()?.child(uid)
    }

    public class func userPath() -> Path? {
        if let userId = currentUserId() {
            return userPath(userId)
        }
        return nil
    }

    public class func messagesPath(_ uid: String) -> Path? {
        return userPath(uid)?.child(Messages)
    }

    public class func messagesPath() -> Path? {
        if let userId = currentUserId() {
            return messagesPath(userId)
        }
        return nil
    }

    public class func userChatsPath() -> Path? {
        if let userId = currentUserId() {
            return userPath(userId)?.child(Keys.Chats)
        }
        return nil
    }

    public class func userMutedPath() -> Path? {
        if let userId = currentUserId() {
            return userPath(userId)?.child(Keys.Muted)
        }
        return nil
    }

    public class func userGroupChatPath(_ chatId: String) -> Path? {
        return userChatsPath()?.child(chatId)
    }

    public class func messagePath(_ messageId: String) -> Path? {
        if let userId = currentUserId() {
            return messagePath(userId, messageId)
        }
        return nil
    }

    public class func messagePath(_ uid: String, _ messageId: String) -> Path? {
        return messagesPath(uid)?.child(messageId)
    }

    internal class func currentUserId() -> String? {
        return Fire.stream().currentUserId()
    }

    public class func contactsPath() -> Path? {
        return userPath()?.child(Contacts)
    }

    public class func blockedPath() -> Path? {
        return userPath()?.child(Blocked)
    }

    public class func chatsPath() -> Path? {
        return root()?.child(Chats)
    }

    public class func chatPath(_ chatId: String) -> Path? {
        return chatsPath()?.child(chatId)
    }

    public class func chatMetaPath(_ chatId: String) -> Path? {
        return chatsPath()?.child(chatId).child(Meta)
    }

    public class func chatMessagesPath(_ chatId: String) -> Path? {
        return chatPath(chatId)?.child(Messages)
    }

    public class func chatUsersPath(_ chatId: String) -> Path? {
        return chatPath(chatId)?.child(Users)
    }

}
