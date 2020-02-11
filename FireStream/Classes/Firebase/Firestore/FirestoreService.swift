//
//  FirestoreService.swift
//  FireStream
//
//  Created by Pepe Becker on 2/10/20.
//

public class FirestoreService: FirebaseService {

    public override init() {
        super.init()
        self.core = FirestoreCoreHandler()
        self.chat = FirestoreChatHandler()
    }

}
