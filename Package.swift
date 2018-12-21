// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HTTPClient",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "HTTPClient",
            targets: ["HTTPClient"]),
    ],
    dependencies: [
        .package(url:"https://github.com/benoit-pereira-da-silva/HMAC", from: "1.0.0"),
        .package(url:"https://github.com/benoit-pereira-da-silva/Globals", from: "1.0.0"),
        .package(url:"https://github.com/benoit-pereira-da-silva/Tolerance", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "HTTPClient",
            dependencies: ["HMAC","Globals","Tolerance"]),
        .testTarget(
            name: "HTTPClientTests",
            dependencies: ["HTTPClient"]),
    ]
)
