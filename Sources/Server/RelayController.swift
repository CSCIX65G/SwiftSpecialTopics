//
//  RelayController.swift
//  Server
//
//  Created by Van Simmons on 3/27/20.
//

import Foundation
import SwiftyGPIO

struct RelayController {
    static var relayReset: MQTTMessaging.MessageProcessor {
        guard HostType.hostType == .rpi else {
            return MQTTMessaging.MessageProcessor(exactlyMatchingTopic: "relay") { _, _ in
                return .failure(MQTTMessaging.Error.unsupportedOperatingSystem)
            }
        }
        guard let pin = SwiftyGPIO.GPIOs(for: .RaspberryPi3)[.pin26] else {
            logger.error("Could not access control pin")
            return MQTTMessaging.MessageProcessor(exactlyMatchingTopic: "relay") { _, _ in
                return .failure(MQTTMessaging.Error.unsupportedHardware)
            }
        }
        return MQTTMessaging.MessageProcessor(exactlyMatchingTopic: "relay") { _, _ in
            pin.direction = .output
            pin.value = true
            sleep(3)
            pin.value = false
            return .success(())
        }
    }
}
