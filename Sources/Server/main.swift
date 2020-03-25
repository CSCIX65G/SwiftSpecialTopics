import Logging
import ArgumentParser
import NIO
import PerfectMosquitto

private let eventLoops = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let logger = Logger(label: "net.playspots.PlayspotDisplayServer")


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

let options = Server.parseOrExit()

logger.info("Server starting")
MQTT.messageThread = eventLoops.next()
do {
    try MQTT.startClient(
        MQTT.messageThread!,
        hostType: options.device,
        host: options.host,
        port: Int32(options.port)
    ).wait()
    
    logger.info("Server shutting down")
    try eventLoops.syncShutdownGracefully()
} catch {
    logger.error("Server start up failed with: \(error)")
}
logger.info("Server exited")
