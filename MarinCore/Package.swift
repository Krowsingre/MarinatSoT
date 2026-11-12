// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MarinCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "MarinCore", targets: ["MarinCore"])
    ],
    targets: [
        .target(name: "MarinCore"),
        .testTarget(name: "MarinCoreTests", dependencies: ["MarinCore"])
    ]
)
