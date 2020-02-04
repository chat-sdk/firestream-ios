//
//  Paths.swift
//  FireStream
//
//  Created by Pepe Becker on 2/4/20.
//

public class Paths: Keys {

    public static func root() -> Path {
        // MARK: TODO
        return Path("Fire.internal().getConfig().getRoot(), Fire.internal().getConfig().getSandbox()")
    }

    public static func usersPath() -> Path {
        return root().child(Users)
    }

    public static func userPath(_ uid: String) -> Path {
        return usersPath().child(uid)
    }

    public static func userPath() -> Path {
        return userPath(currentUserId())
    }

    public static func messagesPath(_ uid: String) -> Path {
        return userPath(uid).child(Messages)
    }

    public static func messagesPath() -> Path {
        return messagesPath(currentUserId())
    }

    public static func userChatsPath() -> Path {
        return userPath(currentUserId()).child(Keys.Chats)
    }

    public static func userMutedPath() -> Path {
        return userPath(currentUserId()).child(Keys.Muted)
    }

    public static func userGroupChatPath(_ chatId: String) -> Path {
        return userChatsPath().child(chatId)
    }

    public static func messagePath(_ messageId: String) -> Path {
        return messagePath(currentUserId(), messageId)
    }

    public static func messagePath(_ uid: String, _ messageId: String) -> Path {
        return messagesPath(uid).child(messageId)
    }

    internal static func currentUserId() -> String {
        // MARK: TODO
        return "Fire.stream().currentUserId()"
    }

    public static func contactsPath() -> Path {
        return userPath().child(Contacts)
    }

    public static func blockedPath() -> Path {
        return userPath().child(Blocked)
    }

    public static func chatsPath() -> Path {
        return root().child(Chats)
    }

    public static func chatPath(_ chatId: String) -> Path {
        return chatsPath().child(chatId)
    }

    public static func chatMetaPath(_ chatId: String) -> Path {
        return chatsPath().child(chatId).child(Meta)
    }

    public static func chatMessagesPath(_ chatId: String) -> Path {
        return chatPath(chatId).child(Messages)
    }

    public static func chatUsersPath(_ chatId: String) -> Path {
        return chatPath(chatId).child(Users)
    }

}
