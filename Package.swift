// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pane",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Pane", targets: ["Pane"])],
    targets: [
        .target(name: "PaneCore"),
        .executableTarget(name: "Pane", dependencies: ["PaneCore"]),
        .testTarget(name: "PaneCoreTests", dependencies: ["PaneCore"])
    ]
)
