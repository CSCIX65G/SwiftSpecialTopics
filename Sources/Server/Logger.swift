//
//  Logger.swift
//  Server
//
//  Created by Van Simmons on 3/29/20.
//

import Foundation
import Logging
import MQTT

func logging(for options: ServerOptions) -> Logger {
    var logger = Logger(label: "net.playspots.PlayspotRelayController")
    logger.logLevel = options.logLevel
    MQTT.log(at: options.logLevel)
    return logger
}

