import Foundation
import ArgumentParser
import NIO
 
let options = ServerOptions.parseOrExit()
let logger = logging(for: options)

logger.info("SpecialTopics starting with log level: \(options.logLevel)")

private let timerLoops = MultiThreadedEventLoopGroup(numberOfThreads: 1)
private let timerLoop = timerLoops.next()

private let serviceLoops = MultiThreadedEventLoopGroup(numberOfThreads: 8)

var count = options.repeats
logger.info("Repeats = \(count)")

func randomIntValue(_ _: Int) -> Int { (0 ..< 1_000_000).randomElement()! }
func generateRandomArray() -> [Int] { (0 ..< 100000).map(randomIntValue) }
func difference(array: [Int]) -> [Int] { zip(array.sorted(by: <), Array(array.sorted(by: <).dropFirst())).map { $0.1 - $0.0 } }
func computationallyIntensiveTask() -> Double {  Double(difference(array: generateRandomArray()).reduce(0, +)) / 9999.0 }

let terminateServer = timerLoop.makePromise(of: Void.self)

let repeatedTask = timerLoop.scheduleRepeatedAsyncTask(
    initialDelay: .milliseconds(20),
    delay: .milliseconds(10)
) { (task) -> EventLoopFuture<Void> in
    count -= 1
    if count == 0 {
        task.cancel()
    }
    guard count >= 0 else { return timerLoop.makeSucceededFuture(()) }
    return serviceLoops.next().submit {
        let avg = computationallyIntensiveTask()
        logger.log(level: .info, "\(count) timer events to go, list avg = \(avg)")
    }
}

func futureComputeTask(_: Int) -> EventLoopFuture<Double> {
    serviceLoops.next().submit(computationallyIntensiveTask)
}

let future = serviceLoops.next().submit(computationallyIntensiveTask)
let futures: [EventLoopFuture<Double>] = (0 ..< 10).map(futureComputeTask)

future.flatMap { _ in EventLoopFuture.andAllComplete(futures, on: serviceLoops.next())}
    .whenComplete { terminateServer.completeWith($0) }

try? terminateServer.futureResult.wait()

logger.info("SpecialTopics exited")
