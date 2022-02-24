// swift-tools-version:5.5
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
            revision: "d31d362"),
    ],
    targets: [
        .target(
            name: "CBSearchKit",
            dependencies: ["FMDB"],
            path: "CBSearchKit/Classes/CBSearchKit",
            sources: ["../../sqlite3", "."],
            publicHeadersPath: "."),
    ]
)
