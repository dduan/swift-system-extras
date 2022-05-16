// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SystemExtras",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "SystemExtras",
            targets: ["SystemExtras"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SystemExtras",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system"),
            ]
        ),
        .testTarget(
            name: "SystemExtrasTests",
            dependencies: ["SystemExtras"]),
    ]
)
