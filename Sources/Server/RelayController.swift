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

func errorHandler(_ swiftError: Swift.Error) {
    guard let error = swiftError as? MQTT.Error else {
        Server.logger.error("Received error: \(swiftError)")
        return
    }
    switch error {
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
    static var resetRelay: MQTT.MessageProcessor {
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
