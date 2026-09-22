// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "FRICore", platforms: [.macOS(.v14)], products: [.library(name: "FRICore", targets: ["FRICore"])], targets: [.target(name: "FRICore", path: "ios/Shared"), .testTarget(name: "FRICoreTests", dependencies: ["FRICore"], path: "Tests/FRICoreTests")])
