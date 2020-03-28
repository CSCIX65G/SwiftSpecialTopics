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
        messageHandlers: [MQTT.MessageProcessor],
        errorHandler: @escaping (Swift.Error) -> Void
    ) -> EventLoopFuture<Void> {
        let m = Mosquitto()
        m.OnMessage    = MQTT.handleMessages(for: messageHandlers, errorHandler: errorHandler)
        m.OnDisconnect = m.handle(disconnect:)
        m.OnConnect    = m.handleConnection(for: messageHandlers.flatMap { $0.subscriptions })
        m.OnLog        = m.handle(logLevel:message:)
        
        do {
            logger.info("Connecting to MQTT server at: \(host):\(port)")
            try m.connect(host: host, port: port, keepAlive: 10, asynchronous: false)
            logger.info("Entering MQTT wait loop")
            return eventLoop.submit {  try m.start(); sleep(86400 * 365 * 10) }
        } catch {
            logger.error("Unable to create MQTT client: \(error)")
            return eventLoop.makeFailedFuture(error)
        }
    }
}
 
extension Mosquitto {
    static var logMask = LogLevel.mask(for: [.INFO])
}

extension Mosquitto.LogLevel {
    static func mask(for levels: [Self]) -> Int32 {
        levels.map(\.rawValue).reduce(0, |)
    }
}

fileprivate extension Mosquitto {
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
                    logger.info("\tSubscribing to: \(topic)")
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
