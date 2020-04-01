import Foundation
import ArgumentParser
import MQTT
 
let options = ServerOptions.parseOrExit()
let logger = logging(for: options)

logger.info("RelayController starting with log level: \(options.logLevel)")

let cancellable = MQTT.start(
    using: [RelayController.resetRelay],
    host: options.host,
    eventHandler: eventHandler
)

try? cancellable.future.wait()
logger.info("RelayController exited")
