//
//  FireStreamError.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

import Foundation

public class FireStreamError: NSError {

    public required init(_ message: String, _ file: String = #file, _ line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        super.init(domain: "", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "\(filename):\(line) \(message)"
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}
