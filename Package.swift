// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CBSearchKit",
    products: [
        .library(name: "CBSearchKit", targets: ["CBSearchKit"]),
    ],
    dependencies: [
        .package(
            name: "FMDB", 
            url: "https://github.com/ccgus/fmdb", 
            .upToNextMinor(from: "2.7.8"),
        ),
    ],
    targets: [
        .target(
            name: "CBSearchKit",
            dependencies: ["FMDB"],
            path: "CBSearchKit",
            sources: ["sqlite3", "Classes/CBSearchKit"],
            publicHeadersPath: "Classes/CBSearchKit",
        ),
    ]
)
