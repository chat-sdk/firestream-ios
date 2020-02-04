//
//  Events.swift
//  FireStream
//
//  Created by Pepe Becker on 1/28/20.
//

import RxSwift

public class Events {

    internal var messages: MultiQueueSubject<FireStreamEvent<Message>>
    internal var deliveryReceipts: MultiQueueSubject<FireStreamEvent<DeliveryReceipt>>
    internal var typingStates: MultiQueueSubject<FireStreamEvent<TypingState>>
    internal var presences: MultiQueueSubject<FireStreamEvent<Presence>>
    internal var invitations: MultiQueueSubject<FireStreamEvent<Invitation>>

    /**
     * The sendable event stream provides the most information. It passes a sendable event
     * when will include the kind of action that has been performed.
     */
    internal var sendables: MultiQueueSubject<FireStreamEvent<Sendable>>

    internal var errors: PublishSubject<Error>

    init() {
        self.messages = MultiQueueSubject()
        self.deliveryReceipts = MultiQueueSubject()
        self.typingStates = MultiQueueSubject()
        self.presences = MultiQueueSubject()
        self.invitations = MultiQueueSubject()
        self.sendables = MultiQueueSubject()
        self.errors = PublishSubject()
    }

    /**
     * Note: when you send a message, that will trigger both a message added event and a
     * message updated event. As soon as the message is added to the Firebase cache, the
     * message added event will be triggered and the message will have an estimated time
     * stamp. Then when the message has been written to the server, it will be updated
     * with the server timestamp.
     * @return
     */
    public func getMessages() -> MultiQueueSubject<FireStreamEvent<Message>> {
        return self.messages
    }

    /**
     * A FireStream Message isType no different from a Message. The reason this method
     * exists isType because Message isType a very common class name. If for any reason
     * your project already has a Message object, you can use the FireStreamMessage
     * to avoid a naming clash
     * @return events of messages
     */
    public func getFireStreamMessages() -> Observable<FireStreamEvent<FireStreamMessage>> {
        return messages.allEvents().filter { $0.get() != nil }
            .map { $0.to(FireStreamMessage.fromMessage($0.get()!)) }
    }

    /**
     * Get a stream of errors from the chat
     * @return
     */
    public func getErrors() -> Observable<Error> {
        return self.errors.asObservable()
    }

    public func getDeliveryReceipts() -> MultiQueueSubject<FireStreamEvent<DeliveryReceipt>> {
        return self.deliveryReceipts
    }

    public func getTypingStates() -> MultiQueueSubject<FireStreamEvent<TypingState>> {
        return self.typingStates
    }

    public func getSendables() -> MultiQueueSubject<FireStreamEvent<Sendable>> {
        return self.sendables
    }

    public func getPresences() -> MultiQueueSubject<FireStreamEvent<Presence>> {
        return self.presences
    }

    public func getInvitations() -> MultiQueueSubject<FireStreamEvent<Invitation>> {
        return self.invitations
    }

    public func publishThrowable() -> PublishSubject<Error> {
        return self.errors
    }

}
