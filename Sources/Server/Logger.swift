//
//  Logger.swift
//  Server
//
//  Created by Van Simmons on 3/29/20.
//

import Foundation
import Logging

func logging(for options: ServerOptions) -> Logger {
    var logger = Logger(label: "org.computecycles.SwiftSpecialTopics")
    logger.logLevel = options.logLevel
    logger.log(level: options.logLevel, "logger initialized")
    return logger
}

