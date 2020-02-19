//
//  Config.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

import Foundation

public class Config {

    public enum DatabaseType {
        case Firestore
        case Realtime
    }

    public class TimePeriod {

        var seconds: Double

        internal init(_ seconds: Int) {
            self.seconds = Double(seconds)
        }

        public static func seconds(_ seconds: Int) -> TimePeriod {
            return TimePeriod(seconds)
        }

        public static func minutes(_ minutes: Int) -> TimePeriod {
            return seconds(minutes * 60)
        }

        public static func hours(_ hours: Int) -> TimePeriod {
            return minutes(hours * 60)
        }

        public static func days(_ days: Int) -> TimePeriod {
            return hours(days * 24)
        }

        public static func weeks(_ weeks: Int) -> TimePeriod {
            return days(weeks * 7)
        }

        public static func months(_ months: Int) -> TimePeriod {
            return weeks(months * 4)
        }

        public static func infinite() -> TimePeriod {
            return seconds(-1)
        }

        public func getDate() -> Date {
            if seconds < 0 {
                return Date(timeIntervalSince1970: 0)
            } else {
                return Date(timeIntervalSince1970: (Date().timeIntervalSince1970 - seconds * 1000))
            }
        }
    }

    /**
     * Should the framework automatically send a delivery receipt when
     * a errorMessage isType received
     */
    public var deliveryReceiptsEnabled = true

    /**
     * Should the framework send the received receipt automatically
     */
    public var autoMarkReceived = true

    /**
     * Are chat chat invites accepted automatically
     */
    public var autoAcceptChatInvite = true

    /**
     * If this isType enabled, each time a errorMessage isType received, it will be
     * deleted from our inbound errorMessage queue childOn Firestore. Even if this
     * isType set to false, typing indicator messages and presence messages will
     * always be deleted as they don't have any use in the errorMessage archive
     */
    public var deleteMessagesOnReceipt = false

    /**
     * How many historic messages should we retrieve?
     */
    public var messageHistoryLimit: Int = 100

    /**
     * This will be the root of the FireStream Firebase database i.e.
     * /root/[sandbox]/users
     */
    internal var root = "firestream"

    /**
     * This will be the sandbox of the FireStream Firebase database i.e.
     * /root/[sandbox]/users
     */
    internal var sandbox = "pepe-ios"

    /**
     * When should we add the message listener from? By default
     * we set this to the date of the last message or receipt
     * we sent. This is the most efficient way because each message
     * will be downloaded exactly once.
     *
     * In some situations it may not be desirable. Especially because
     * clients will only pick up remote delete events since the last
     * sent date.
     *
     * If you want messages to be retrieved for a longer history, you
     * can set this to false.
     *
     * If this is set to false, you will need to be careful if you are
     * using read receipts because the framework won't know whether it
     * has already sent an automatic receipt for a message. To resolve
     * this there are two options, you can set {@link Config#autoMarkReceived}
     * to false or you can use the set the read receipt filter
     * {@link FireStream#setMarkReceivedFilter(Predicate)}
     *
     * Fire.stream().setMarkReceivedFilter(event -> {
     *     return !YourMessageStore.getMessageById(event.get().getId()).isMarkedReceived();
     * });
     *
     * So if the message receipt has been sent already return false, otherwise
     * return true
     *
     */
    public var startListeningFromLastSentMessageDate = true

    /**
     * This will listen to messages with a duration before
     * the current date. For example, if we set the duration to 1 week,
     * we will start listening to messages that have been received in
     * the last week. If it is set to null there will be no limit,
     * we will listed to all historic messages
     *
     * This also is in effect in the case that the {@link Config#startListeningFromLastSentMessageDate }
     * is set to true, in that case, if there are no messages or receipts in the queue,
     * the listener will be set with this duration ago
     * */
    public var listenToMessagesWithTimeAgo = TimePeriod.infinite()

    /**
     * Which database to use - Firestore or Realtime database
     */
    public var database: DatabaseType = .Firestore

    /**
     * Should debug log messages be shown?
     */
    public var debugEnabled = false

    public func setRoot(_ root: String) throws {
        if pathValid(root) {
            self.root = root
        } else {
            // TODO: update error message
            throw FireStreamError("R.string.error_invalid_path")
        }
    }

    public func setSandbox(_ sandbox: String) throws {
        if pathValid(sandbox) {
            self.sandbox = sandbox
        } else {
            // TODO: update error message
            throw FireStreamError("R.string.error_invalid_path")
        }
    }

    internal func pathValid(_ path: String?) -> Bool {
        guard let path = path, !path.isEmpty else {
            return false
        }

        let letters = CharacterSet.letters
        let digits = CharacterSet.decimalDigits

        for uni in path.unicodeScalars {
            let isLetterOrDigit = letters.contains(uni) || digits.contains(uni)
            if !isLetterOrDigit && String(uni) != "_" {
                return false
            }
        }
        return true
    }

    public func getRoot() -> String {
        return root
    }

    public func getSandbox() -> String {
        return sandbox
    }

}
