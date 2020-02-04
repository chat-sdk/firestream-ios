//
//  FireStreamError.swift
//  FireStream
//
//  Created by Pepe Becker on 1/30/20.
//

import Foundation

public class FireStreamError: NSError {

    public required init(_ message: String) {
        super.init(domain: "", code: 0, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}
