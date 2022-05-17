// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "swift-system-extras",
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
            ],
            cSettings: [
                .define("_CRT_SECURE_NO_WARNINGS")
            ]
        ),
        .testTarget(name: "SystemExtrasTests", dependencies: ["SystemExtras"]),

    ] + [
        // Examples
        "cwd",
        "mkdir",
    ].map { name in
        .executableTarget(
            name: name,
            dependencies: [.target(name: "SystemExtras")],
            path: "Examples/\(name)"
        )
    }
)
