import Foundation
import ArgumentParser
import NIO
 
let options = ServerOptions.parseOrExit()
let logger = logging(for: options)

logger.info("SpecialTopics starting with log level: \(options.logLevel)")

private let timerLoops = MultiThreadedEventLoopGroup(numberOfThreads: 1)
private let timerLoop = timerLoops.next()

private let serviceLoops = MultiThreadedEventLoopGroup(numberOfThreads: 3)
var count = 10

let promise = timerLoop.makePromise(of: Void.self)

let repeatedTask = timerLoop.scheduleRepeatedAsyncTask(
    initialDelay: .milliseconds(2000),
    delay: .milliseconds(1000)
) { (task) -> EventLoopFuture<Void> in
    count -= 1
    guard count >= 0 else { return timerLoop.makeSucceededFuture(()) }
    return serviceLoops.next().submit {
        logger.log(level: .info, "\(count) timer events to go")
        if count == 0 {
            task.cancel()
            promise.completeWith(.success(()))
        }
    }
}

logger.info("SpecialTopics waiting")

try? promise.futureResult.wait()

logger.info("SpecialTopics exited")
