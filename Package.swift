// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrinitiwowkaCapacitorTrueTime",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "TrinitiwowkaCapacitorTrueTime", targets: ["RawNtpPlugin"])
    ],
    dependencies: [
        // Match your app's Capacitor major version
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "RawNtpPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/RawNtpPlugin"
        )
    ]
)
