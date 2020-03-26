import Logging
import ArgumentParser
import NIO
import PerfectMosquitto
import Foundation

public enum HostType: ExpressibleByArgument {
    case rpi
    case mac

    public init?(argument: String) {
        switch argument.lowercased() {
        case "rpi": self = .rpi
        case "mac": self = .mac
        default: return nil
        }
    }
}


struct Server: ParsableCommand {
    @Argument(
        default: "relaycontroller",
        help: ArgumentHelp("handle different pi convention", valueName: "device")
    )
    var program: String
    
    @Option(
        default: .rpi,
        help: ArgumentHelp("device type to run on", valueName: "device")
    )
    var device: HostType

    @Option(
        default: "192.168.2.1",
        help: ArgumentHelp("mqtt host", valueName: "host")
    )
    var host: String

    @Option(
        default: 1883,
        help: ArgumentHelp("mqtt port", valueName: "port")
    )
    var port: Int
}

private let options = Server.parseOrExit()
private let eventLoops = MultiThreadedEventLoopGroup(numberOfThreads: 1)

let logger = Logger(label: "net.playspots.PlayspotRelayController")
logger.info("Server starting")
do {
    MQTT.hostType = options.device
    try MQTT.startClient(
        eventLoops.next(),
        host: options.host,
        port: Int32(options.port)
    ).wait()
    
    logger.info("Server shutting down")
    try eventLoops.syncShutdownGracefully()
} catch {
    logger.error("Server start up failed with: \(error)")
}
logger.info("Server exited")
