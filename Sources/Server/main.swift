import Foundation
import ArgumentParser
import NIO
 
let options = ServerOptions.parseOrExit()
let logger = logging(for: options)

logger.info("SpecialTopics starting with log level: \(options.logLevel)")

private let timerLoops = MultiThreadedEventLoopGroup(numberOfThreads: 1)
private let timerLoop = timerLoops.next()

private let serviceLoops = MultiThreadedEventLoopGroup(numberOfThreads: 4)
var count = options.repeats

logger.info("SpecialTopics exited")
