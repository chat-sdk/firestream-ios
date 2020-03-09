//
//  RealtimeService.swift
//  FireStream
//
//  Created by Pepe Becker on 3/6/20.
//

public class RealtimeService: FirebaseService {

    public override init() {
        super.init()
        self.core = RealtimeCoreHandler()
        self.chat = RealtimeChatHandler()
    }

}
