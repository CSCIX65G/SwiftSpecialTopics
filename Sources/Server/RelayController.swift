//
//  RelayController.swift
//  Server
//
//  Created by Van Simmons on 3/27/20.
//

import Foundation
import SwiftyGPIO

struct RelayController {
    static var relayReset: MQTT.MessageProcessor {
        guard HostType.hostType == .rpi else {
            return MQTT.MessageProcessor(exactlyMatchingTopic: "relay") { _ in
                return .failure(MQTT.Error.unsupportedOperatingSystem)
            }
        }
        guard let pin = SwiftyGPIO.GPIOs(for: .RaspberryPi3)[.pin26] else {
            logger.error("Could not access control pin")
            return MQTT.MessageProcessor(exactlyMatchingTopic: "relay") { _ in
                return .failure(MQTT.Error.unsupportedHardware)
            }
        }
        return MQTT.MessageProcessor(exactlyMatchingTopic: "relay") { _ in
            pin.direction = .output
            pin.value = true
            sleep(3)
            pin.value = false
            return .success(())
        }
    }
}
