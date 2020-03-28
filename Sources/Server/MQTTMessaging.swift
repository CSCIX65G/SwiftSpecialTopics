//
//  MQTTMessageHandlers.swift
//  Server
//
//  Created by Van Simmons on 3/27/20.
//

import Foundation
import PerfectMosquitto
import NIO
import SwiftyGPIO

struct MQTTMessaging {
    typealias MessageMatcher = (String, Data) -> Bool
    typealias MessageResult  = Result<Void, Swift.Error>
    typealias MessageHandler = (String, Data) -> MessageResult
    typealias ErrorHandler = (MQTTMessaging.Error) -> Void
    
    enum Error: Swift.Error {
        case throttled
        case unhandled
        case unsupportedOperatingSystem
        case unsupportedHardware
        case handlerError(Swift.Error)
        func failure(for eventLoop: EventLoop) -> EventLoopFuture<MessageResult> {
            return eventLoop.makeFailedFuture(self)
        }
    }

    struct MessageProcessor {
        let subscriptions: [String]
        let matcher: MessageMatcher
        let handler: MessageHandler
        
        static let unsupportedOperatingSystem = MQTTMessaging.MessageProcessor(
            subscriptions: [],
            matcher: { _, _ in false },
            handler: { (_, _) in .failure(MQTTMessaging.Error.unsupportedOperatingSystem) }
        )

        static let unsupportedHardware = MQTTMessaging.MessageProcessor(
            subscriptions: [],
            matcher: { _, _ in false },
            handler: { (_, _) in .failure(MQTTMessaging.Error.unsupportedHardware) }
        )

        static func exactlyMatch(_ match: String) -> MessageMatcher {
            { value, _  in match == value }
        }
        
        init(subscriptions: [String], matcher: @escaping MessageMatcher, handler: @escaping MessageHandler) {
            self.subscriptions = subscriptions
            self.matcher = matcher
            self.handler = handler
        }
        
        init(exactlyMatchingTopic topic: String, handler: @escaping MessageHandler) {
            self.subscriptions = [topic]
            self.matcher = MessageProcessor.exactlyMatch(topic)
            self.handler = handler
        }
    }
    
    static var eventLoop: EventLoop!
    static var throttlingInterval = 0.5
}

extension MQTTMessaging {
    @discardableResult
    static func submitMessages(
        for topics: [MQTTMessaging.MessageProcessor]
    ) -> (inout Date, Mosquitto.Message) -> EventLoopFuture<MessageResult> {
        return { lastCall, msg in
            let now = Date()
            guard now.timeIntervalSince(lastCall) > throttlingInterval else {
                return MQTTMessaging.Error.throttled.failure(for: eventLoop)
            }
            guard let handler = topics.first(where: \.matcher)?.handler else {
                return MQTTMessaging.Error.unhandled.failure(for: eventLoop)
            }
            lastCall = now
            return MQTTMessaging.eventLoop.submit {
                let unsigned = msg.payload.map { UInt8($0) }
                return handler(msg.topic, Data(unsigned))
                    .mapError { MQTTMessaging.Error.handlerError($0) }
            }
        }
    }
    
    static func handleMessages(
        for topics: [MQTTMessaging.MessageProcessor],
        errorHandler: @escaping (Swift.Error) -> Void
    ) -> (Mosquitto.Message) -> Void {
        var lastCall = Date()
        return { msg in
            submitMessages(for: topics)(&lastCall, msg)
                .flatMapThrowing { try $0.get() }
                .whenFailure(errorHandler)
            return
        }
    }
}
