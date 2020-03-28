//
//  ServerOptions.swift
//  Server
//
//  Created by Van Simmons on 3/27/20.
//

import Foundation
import ArgumentParser
import Logging

struct ServerOptions: ParsableCommand {
    @Argument(
        default: "relaycontroller",
        help: ArgumentHelp("handle different pi convention", valueName: "device")
    )
    var program: String
    
    @Option(
        name: .long,
        default: "192.168.2.1",
        help: ArgumentHelp("MQTT host", valueName: "host")
    )
    var host: String

    @Option(
        name: .long,
        default: 1883,
        help: ArgumentHelp("MQTT port", valueName: "port")
    )
    var port: Int

    @Option(
        name: .customLong("logLevel"),
        default: .info,
        help: ArgumentHelp("log level: trace | debug | info | notice | warning | error | critical", valueName: "logLevel")
    )
    var logLevel: Logger.Level
}

