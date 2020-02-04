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

    /**
     * Should the framework automatically send a delivery receipt when
     * a errorMessage isType received
     */
    public var deliveryReceiptsEnabled = true

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
    internal var sandbox = "prod"

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
            // MARK: TODO
            throw FireStreamError("R.string.error_invalid_path")
        }
    }

    public func setSandbox(_ sandbox: String) throws {
        if pathValid(sandbox) {
            self.sandbox = sandbox
        } else {
            // MARK: TODO
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
