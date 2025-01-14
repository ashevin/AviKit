// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AviKit",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "AviKit",
            targets: ["AviKit"]),
    ],
    dependencies: [
		.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
	.target(
	    name: "AviKit",
	    dependencies: []),
        .testTarget(
            name: "AviKitTests",
            dependencies: ["AviKit"]),
    ]
)

