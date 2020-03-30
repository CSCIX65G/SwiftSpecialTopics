import Foundation
import ArgumentParser
import MQTT
 
let options = ServerOptions.parseOrExit()
let logger = logging(for: options)

logger.info("Server starting with log level: \(options.logLevel)")

let cancellable = MQTT.start(
    using: [RelayController.resetRelay],
    host: options.host,
    errorHandler: errorHandler
)

try? cancellable.wait()
logger.info("Server exited")
