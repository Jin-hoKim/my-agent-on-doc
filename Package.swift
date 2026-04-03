// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MyAgentOnDock",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyAgentOnDock",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios"),
            ],
            path: "MyAgentOnDock",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
