import Foundation
import NIO
import Logging
import ArgumentParser
import MQTT
 
private let options = ServerOptions.parseOrExit()
private let eventLoops = MultiThreadedEventLoopGroup(numberOfThreads: 1)

let logger = logging(for: options)
logger.info("Server starting with log level: \(options.logLevel)")

let cancellable = MQTT.start(
    receivingOn: eventLoops.next(),
    throttledAt: 0.5,
    using: [RelayController.resetRelay],
    host: options.host,
    errorHandler: errorHandler
)

do {
    try cancellable.wait()    
    logger.info("Server shutting down")
    try eventLoops.syncShutdownGracefully()
} catch {
    logger.error("Server start up failed with: \(error)")
}

logger.info("Server exited")
