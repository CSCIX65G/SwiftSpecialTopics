// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let dependencies: [PackageDescription.Package.Dependency] = [
    .package(url: "git@github.com:apple/swift-argument-parser",    .upToNextMajor(from: "0.0.4")),
    .package(url: "git@github.com:apple/swift-nio.git",            .upToNextMajor(from: "2.14.0")),
    .package(url: "git@github.com:apple/swift-log.git",            .upToNextMajor(from: "1.2.0")),
    .package(url: "git@github.com:CSCIX65G/Perfect-Mosquitto.git", .branch("master")),
    .package(url: "git@github.com:uraimo/SwiftyGPIO",              .branch("next_release"))
]

let serverTargetDependencies: [Target.Dependency] = [
    "ArgumentParser",
    "PerfectMosquitto",
    "SwiftyGPIO",
    "Logging",
    "NIO"
]

#if os(macOS)

let package = Package(
    name: "relaycontroller",
    platforms: [
       .macOS(.v10_14),
    ],
    products: [
        .executable(
            name: "relaycontroller",
            targets: [
                "Server",
            ]
        ),
    ],
    dependencies: dependencies,
    targets: [
        .target(
            name: "Server",
            dependencies: serverTargetDependencies
        ),
        .testTarget(
            name: "ServerTests",
            dependencies: ["Server"]
        ),
    ]
)

#else

let package = Package(
    name: "relaycontroller",
    products: [
        .executable(
            name: "relaycontroller",
            targets: [
                "Server",
            ]
        ),
    ],
    dependencies: dependencies,
    targets: [
        .target(
            name: "Server",
            dependencies: serverTargetDependencies
        ),
        .testTarget(
            name: "ServerTests",
            dependencies: ["Server"]
        ),
    ]
)

#endif
