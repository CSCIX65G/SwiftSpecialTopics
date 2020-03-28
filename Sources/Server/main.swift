import Logging
import ArgumentParser
import NIO
import PerfectMosquitto
import Foundation
import SwiftyGPIO

public enum HostType {
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

private func logging(for options: ServerOptions) -> Logger {
    var logger = Logger(label: "net.playspots.PlayspotRelayController")
    logger.logLevel = options.logLevel
    
    switch options.logLevel {
    case .trace: Mosquitto.logMask = Mosquitto.LogLevel.mask(for: [.ALL, .DEBUG, .ERR, .INFO, .NOTICE, .SUBSCRIBE, .UNSUBSCRIBE])
    case .debug: Mosquitto.logMask = Mosquitto.LogLevel.mask(for: [.DEBUG, .ERR, .INFO, .NOTICE, .SUBSCRIBE, .UNSUBSCRIBE])
    case .info: Mosquitto.logMask = Mosquitto.LogLevel.mask(for: [.ERR, .NOTICE, .SUBSCRIBE, .UNSUBSCRIBE])
    case .notice, .warning: Mosquitto.logMask = Mosquitto.LogLevel.mask(for: [.ERR, .NOTICE])
    case .error, .critical: Mosquitto.logMask = Mosquitto.LogLevel.mask(for: [.ERR])
    }
    return logger
}

private func errorHandler(_ error: Error) {
    guard let error = error as? MQTT.Error else { return }
    switch error {
    case .throttled: logger.error("Throttled MQTT handling")
    case .unhandled: logger.error("Received unhandled message")
    case .unsupportedOperatingSystem: logger.error("R/Pi required")
    case .unsupportedHardware: logger.error("Unable to access hardware")
    case .handlerError(let innerError): logger.error("received \(innerError) while handling message")
    }
}

private let options = ServerOptions.parseOrExit()
private let eventLoops = MultiThreadedEventLoopGroup(numberOfThreads: 2)
let logger = logging(for: options)
logger.info("Server starting with log level: \(options.logLevel)")

do {
    MQTT.eventLoop = eventLoops.next()
    try MQTT.startClient(
        eventLoops.next(),
        host: options.host,
        port: Int32(options.port),
        messageHandlers: [RelayController.relayReset],
        errorHandler: errorHandler
    ).wait()
    
    logger.info("Server shutting down")
    try eventLoops.syncShutdownGracefully()
} catch {
    logger.error("Server start up failed with: \(error)")
}

logger.info("Server exited")
