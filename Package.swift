// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CBSearchKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "CBSearchKit", targets: ["CBSearchKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ccgus/fmdb", from: "2.7.5"),
    ],
    targets: [
        .target(
            name: "CBSearchKit",
            dependencies: [
                .product(name: "FMDB", package: "fmdb"),
            ],
            path: "Sources/CBSearchKit",
            publicHeadersPath: "include"),
        .testTarget(
            name: "CBSearchKitTests",
            dependencies: ["CBSearchKit"],
            path: "Tests/CBSearchKitTests"),
    ]
)
