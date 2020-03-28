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
import Overture

extension MQTT {
    typealias MessageMatcher = (Mosquitto.Message) -> Bool
    typealias MessageResult  = Result<Void, Swift.Error>
    typealias MessageHandler = (Mosquitto.Message) -> MessageResult
    typealias ErrorHandler = (MQTT.Error) -> Void
    
    enum Error: Swift.Error {
        case throttled
        case unhandled
        case unsupportedOperatingSystem
        case unsupportedHardware
        case handlerError(Swift.Error)
    }

    struct MessageProcessor {
        let subscriptions: [String]
        let matcher: MessageMatcher
        let handler: MessageHandler
        static func exactlyMatch(_ match: String) -> MessageMatcher {
            { message  in match == message.topic }
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
        
        static func matcher(_ p: MQTT.MessageProcessor) -> MessageMatcher { p.matcher }
        static func handler(_ p: MQTT.MessageProcessor) -> MessageHandler { p.handler }
    }
    
    static var eventLoop: EventLoop!
    static var throttlingInterval = 0.5
}

extension Mosquitto.Message {
    var payloadData: Data { Data(payload.map { UInt8($0) })}
}

extension MQTT {
    @discardableResult
    static func submitMessage(
        for topics: [MQTT.MessageProcessor]
    ) -> (inout Date, Mosquitto.Message) -> EventLoopFuture<MessageResult> {
        return { lastCall, msg -> EventLoopFuture<MessageResult> in
            let now = Date()
            guard now.timeIntervalSince(lastCall) > throttlingInterval else {
                return MQTT.eventLoop.makeFailedFuture(MQTT.Error.throttled)
            }
            let matcher = flip(MQTT.MessageProcessor.matcher)(msg)
            guard let handler = topics.first(where: matcher)?.handler else {
                return MQTT.eventLoop.makeFailedFuture(MQTT.Error.unhandled)
            }
            lastCall = now
            return MQTT.eventLoop.submit {
                handler(msg).mapError(MQTT.Error.handlerError)
            }
        }
    }
    
    static func handleMessages(
        for topics: [MQTT.MessageProcessor],
        errorHandler: @escaping (Swift.Error) -> Void
    ) -> (Mosquitto.Message) -> Void {
        var lastCall = Date()
        return { msg in
            submitMessage(for: topics)(&lastCall, msg)
                .flatMapThrowing(zurry(flip(MessageResult.get)))
                .whenFailure(errorHandler)
            return
        }
    }
}
