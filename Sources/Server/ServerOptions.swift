//
//  ServerOptions.swift
//  Server
//
//  Created by Van Simmons on 3/27/20.
//

import Foundation
import ArgumentParser
import Logging

enum HostType {
    case rpi
    case mac

    #if os(macOS)
    static let hostType: HostType = .mac
    #else
    static let hostType: HostType = .rpi
    #endif
    
    public init?(argument: String) {
        switch argument.lowercased() {
        case "rpi": self = .rpi
        case "mac": self = .mac
        default: return nil
        }
    }
}

extension Logger.Level: ExpressibleByArgument { }

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

