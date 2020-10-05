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
        help: ArgumentHelp("handle different pi convention", valueName: "device")
    )
    var program: String = "specialtopics"

    @Option(
        name: .customLong("logLevel"),
        help: ArgumentHelp("log level: trace | debug | info | notice | warning | error | critical", valueName: "logLevel")
    )
    var logLevel: Logger.Level = .info

    @Option(
        name: .customLong("repeats"),
        help: ArgumentHelp("repeats N", valueName: "repeats")
    )
    var repeats: Int = 1
}

