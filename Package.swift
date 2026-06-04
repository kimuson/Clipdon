// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Clipdon",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Clipdon",
            path: "Sources/Clipdon"
        )
    ]
)
