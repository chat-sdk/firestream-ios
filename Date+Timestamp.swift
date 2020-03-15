//
//  Date+Timestamp.swift
//  FireStream
//
//  Created by Pepe Becker on 3/15/20.
//

import UIKit

extension Date {

    public init(timestamp: TimeInterval) {
        self.init(timeIntervalSince1970: timestamp / 1000)
    }

    public var timestamp: TimeInterval {
        get {
            return self.timeIntervalSince1970 * 1000
        }
    }

}
