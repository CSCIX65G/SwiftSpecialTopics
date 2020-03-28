//
//  MQTTClient.swift
//  
//
//  Created by Van Simmons on 10/13/19.
//

import Foundation
import Logging
import PerfectMosquitto
import NIO

struct MQTT {
    public static func startClient(
        _ eventLoop: EventLoop,
        host: String,
        port: Int32,
        messageHandlers: [MQTTMessaging.MessageProcessor],
        errorHandler: @escaping (Error) -> Void
    ) -> EventLoopFuture<Void> {
        let m = Mosquitto()
        m.OnMessage    = MQTTMessaging.handleMessages(for: messageHandlers, errorHandler: errorHandler)
        m.OnDisconnect = m.handle(disconnect:)
        m.OnConnect    = m.handleConnection(for: messageHandlers.flatMap { $0.subscriptions })
        m.OnLog        = m.handle(logLevel:message:)
        
        do {
            logger.info("Connecting to MQTT server at: \(host):\(port)")
            try m.connect(host: host, port: port, keepAlive: 10, asynchronous: false)
            logger.info("Entering MQTT wait loop")
            return eventLoop.submit { () throws -> Void in
                try m.start()
                sleep(86400)
            }
        } catch {
            logger.error("Unable to create MQTT client: \(error)")
            let promise = eventLoop.makePromise(of: Void.self)
            let future = promise.futureResult
            promise.fail(error)
            return future
        }
    }
}
 
extension Mosquitto {
    static var logMask = LogLevel.DEBUG.rawValue & LogLevel.INFO.rawValue
}
extension Mosquitto.LogLevel {
    static func mask(for levels: [Self]) -> Int32 {
        levels.map { $0.rawValue }.reduce(0, |)
    }
}

extension Mosquitto {
    func handle(disconnect status: Mosquitto.ConnectionStatus) -> Void {
        guard status == .ELSE else { return }
        do {
            logger.info("Reconnecting MQTT after status \(status)...")
            try reconnect(false)
        } catch {
            logger.error("Could not reconnect: \(error)")
        }
    }

    func handleConnection(for topics:[String]) -> (Mosquitto.ConnectionStatus) -> Void {
        return { status in
            logger.info("Connected to MQTT with status \(status)...")
            topics.forEach { topic in
                do {
                    logger.info("Subscribing to: \(topic)")
                    try self.subscribe(topic: topic)
                } catch {
                    logger.error("Unable to subscript to relay topic: \(error)")
                }
            }
        }
    }
    
    func handle(logLevel: LogLevel, message: String) {
        guard (logLevel.rawValue & Mosquitto.logMask) > 0 else { return }
        logger.info("\(message)")
    }
}
