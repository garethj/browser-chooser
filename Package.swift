// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "BrowserChooser",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "BrowserChooser",
            dependencies: ["TOMLKit"],
            path: "Sources/BrowserChooser"
        ),
        .testTarget(
            name: "BrowserChooserTests",
            dependencies: ["BrowserChooser"],
            path: "Tests/BrowserChooserTests"
        ),
    ]
)
