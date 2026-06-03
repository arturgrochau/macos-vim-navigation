// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KeyDeck",
    platforms: [.macOS(.v13)],
    targets: [
        // Pure logic: config model, file IO, validation. No UI — fully testable.
        .target(name: "KeyDeckCore"),
        // SwiftUI editor that depends on the core.
        .executableTarget(name: "KeyDeck", dependencies: ["KeyDeckCore"]),
        .testTarget(name: "KeyDeckCoreTests", dependencies: ["KeyDeckCore"]),
    ]
)
