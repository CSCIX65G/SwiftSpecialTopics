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
import SwiftyGPIO

public struct DisplayMessage: Codable, Equatable, CustomStringConvertible {
    static let jsonDecoder = JSONDecoder()
    
    public static func decode(_ data: Data) -> DisplayMessage? {
        try? Self.jsonDecoder.decode(DisplayMessage.self, from: data)
    }

    public let image: String
    public let text: String
    
    public init(image: String = "Empty", text: String = "") {
        self.image = image
        self.text = text
    }
    
    public init?(data: Data) {
        guard let decoded = Self.decode(data) else { return nil }
        self = decoded
    }
    
    public var description: String { return "\"\(image)\")" }
    
    enum CodingKeys: String, CodingKey {
        case image
        case text
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.image = try container.decodeIfPresent(String.self, forKey: .image) ?? "Empty"
        self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
    }

}

public struct MQTT {
    static var hostType: HostType = .rpi

    public static func startClient(
        _ eventLoop: EventLoop,
        host: String,
        port: Int32
    ) -> EventLoopFuture<Void> {
        let m = Mosquitto()
        m.OnMessage    = m.handleMessages()
        m.OnDisconnect = m.handle(disconnect:)
        m.OnConnect    = m.handle(connect:)
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
 
fileprivate extension Mosquitto {
    func handleMessages() -> (Mosquitto.Message) -> Void {
        var lastCall = Date()
        return { msg in
            let now = Date()
            guard now.timeIntervalSince(lastCall) > 0.5,
                MQTT.hostType == .rpi,
                let pin = SwiftyGPIO.GPIOs(for: .RaspberryPi3)[.pin26]
                else {
                    logger.error("Could not handle message for hostType = \(MQTT.hostType)")
                    return
                }
            lastCall = now
            guard msg.topic == "relay" else { return }
            pin.direction = .output
            logger.info("Turning off relay")
            pin.value = true
            logger.info("Turned off relay")
            sleep(5)
            logger.info("Turning on relay")
            pin.value = false
            logger.info("Turned on relay")
        }
    }
    
    func handle(disconnect status: Mosquitto.ConnectionStatus) -> Void {
        guard status == .ELSE else { return }
        do {
            logger.info("Reconnecting MQTT after status \(status)...")
            try reconnect(false)
        } catch {
            logger.error("Could not reconnect: \(error)")
        }
    }

    func handle(connect status: Mosquitto.ConnectionStatus) -> Void {
        logger.info("Connected MQTT with status \(status)...")
        logger.info("Subscribing to `relay` topic")
        do {
            try subscribe(topic: "relay")
        } catch {
            logger.error("Unable to subscript to relay topic: \(error)")
        }
    }
    
    func handle(logLevel: LogLevel, message: String) {
        guard logLevel != .DEBUG else { return }
        logger.info("\(message)")
    }
}
