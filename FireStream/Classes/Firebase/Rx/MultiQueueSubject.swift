//
//  MultiQueueSubject.swift
//  FireStream
//
//  Created by Pepe Becker on 1/29/20.
//

import RxSwift

public class MultiQueueSubject<T>: ObserverType {

    public typealias Element = T

    internal let publishSubject: PublishSubject<T>
    internal let replaySubject: ReplaySubject<T>
    internal let behaviorSubject: BehaviorSubject<T?>

    public init() {
        self.publishSubject = PublishSubject()
        self.replaySubject = ReplaySubject.createUnbounded()
        self.behaviorSubject = BehaviorSubject(value: nil)
    }

    public func onNext(_ element: T) {
        if self.publishSubject.hasObservers {
            self.publishSubject.onNext(element)
        }
        self.replaySubject.onNext(element)
        self.behaviorSubject.onNext(element)
    }

    public func onError(_ error: Error) {
        if self.publishSubject.hasObservers {
            self.publishSubject.onError(error)
        }
        self.replaySubject.onError(error)
        self.behaviorSubject.onError(error)
    }

    public func onCompleted() {
        self.publishSubject.onCompleted()
        self.replaySubject.onCompleted()
        self.behaviorSubject.onCompleted()
    }

    public func on(_ event: Event<T>) {
        if let error = event.error {
            onError(error)
        } else if event.isCompleted {
            onCompleted()
        } else if let element = event.element {
            onNext(element)
        }
    }

    public func newEvents() -> Observable<T> {
        return self.publishSubject.asObservable()
    }

    public func allEvents() -> Observable<T> {
        return self.replaySubject.asObservable()
    }

    public func sinceLastEvent() -> Observable<T> {
        return self.behaviorSubject.filter({ $0 != nil }).map({ $0! })
    }

}
