// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrinitiwowkaCapacitorTrueTime",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "TrinitiwowkaCapacitorTrueTime",
            targets: ["TrueTimePlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "CTrueTime",
            path: "ios/Vendor/TrueTime/Sources/CTrueTime",
            publicHeadersPath: "."),
        .target(
            name: "TrueTime",
            dependencies: ["CTrueTime"],
            path: "ios/Vendor/TrueTime/Sources",
            exclude: ["CTrueTime"]),
        .target(
            name: "TrueTimePlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                "TrueTime"
            ],
            path: "ios/Sources/TrueTimePlugin")
    ]
)
