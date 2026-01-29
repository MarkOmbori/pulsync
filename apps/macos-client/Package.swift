// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PulsyncClient",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "PulsyncClient",
            path: "Sources"
        ),
    ]
)
