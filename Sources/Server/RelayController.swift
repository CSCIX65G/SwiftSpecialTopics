//
//  RelayController.swift
//  Server
//
//  Created by Van Simmons on 3/27/20.
//

import Foundation
import SwiftyGPIO
import Logging
import MQTT

func eventHandler(_ event: MQTT.Event<Void>) {
    switch event {
    case .clientStarted:
        Server.logger.trace("Server started")
    case .messageHandled(let resultArray):
        resultArray.forEach { result in
            switch result {
            case .success:
                Server.logger.trace("Message handled")
            case .failure(let error):
                errorHandler(error)
            }
        }
    case .clientPaused:
        Server.logger.trace("Server paused")
    case .clientStopped:
        Server.logger.trace("Server stopped")
    case .clientError(let error):
        errorHandler(error)
    case .clientConnected:
        Server.logger.trace("Server connected to MQTT")
    case .clientReconnected:
        Server.logger.trace("Server reconnected to MQTT")
    case .clientConnecting(let host, let port):
        Server.logger.trace("Server connecting @\(host):\(port)")
    case .clientSubscribed(let topic):
        Server.logger.trace("Server subscribed to: @\(topic)")
    }
}
 
func errorHandler(_ swiftError: Swift.Error) {
    guard let error = swiftError as? MQTT.Error else {
        Server.logger.error("Received error: \(swiftError)")
        return
    }
    switch error {
    case .couldNotStart:
        Server.logger.error("MQTT client must run for at least 1 second")
    case .mosquittoError(let innerError):
        Server.logger.error("received \(innerError) from Mosquitto")
    case .throttled:
        Server.logger.error("Throttled MQTT handling")
    case .unhandledMessage:
        Server.logger.error("Received unhandled message")
    case .unsupportedOperatingSystem:
        Server.logger.error("R/Pi required for GPIO operations")
    case .unsupportedHardware:
        Server.logger.error("Could not access controller pin")
    case .badTopic:
        Server.logger.error("Topic as provided could not be parsed")
    case .handlerError(let innerError):
        guard let err = innerError as? MQTT.Error else {
            Server.logger.error("received \(innerError) while handling message")
            return
        }
        errorHandler(err)
    }
}

struct RelayController {
    static var resetRelay: MQTT.MessageProcessor<Void> {
        guard HostType.hostType == .rpi else {
            return MessageProcessor(matching: "relay") { _,_  in
                .failure(MQTT.Error.unsupportedOperatingSystem)
            }!
        }
        guard let pin = SwiftyGPIO.GPIOs(for: .RaspberryPi3)[.pin26] else {
            return MQTT.MessageProcessor(matching: "relay") { _, _ in
                .failure(MQTT.Error.unsupportedHardware)
            }!
        }
        return MQTT.MessageProcessor(matching: "relay") { _, _ in
            pin.direction = .output
            pin.value = true
            sleep(3)
            pin.value = false
            return .success(())
        }!
    }
}
