// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let dependencies: [PackageDescription.Package.Dependency] = [
    .package(url: "git@github.com:apple/swift-argument-parser",    .upToNextMajor(from: "0.0.4")),
    .package(url: "git@github.com:apple/swift-nio.git",            .upToNextMajor(from: "2.14.0")),
    .package(url: "git@github.com:apple/swift-log.git",            .upToNextMajor(from: "1.2.0"))
]

let serverTargetDependencies: [Target.Dependency] = [
    "ArgumentParser",
    "Logging",
    "NIO"
]

#if os(macOS)

let package = Package(
    name: "specialtopics",
    platforms: [
       .macOS(.v10_14),
    ],
    products: [
        .executable(
            name: "specialtopics",
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
    name: "specialtopics",
    products: [
        .executable(
            name: "specialtopics",
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
