// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let package = Package(
    name: "Harmony",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Harmony",
            targets: ["Harmony"]
        ),
        .library(
            name: "HarmonyDynamic",
            type: .dynamic,
            targets: ["Harmony"]
        ),
        .library(
            name: "HarmonyStatic",
            type: .static,
            targets: ["Harmony"]
        ),
        // Removed example due to circular dependency with sub-modules, HarmonyDrive/HarmonyDropbox
//        .executable(name: "Example", targets: ["Example"])
    ],
    dependencies: [
         .package(url: "https://github.com/JoeMatt/Roxas.git", from: "1.0.2"),
         //        .package(path: "../Roxas")
//         .package(url: "https://github.com/JoeMatt/Harmony-Drive.git", from: "1.0.0"),
//         .package(url: "https://github.com/JoeMatt/Harmony-Dropbox.git", from: "1.0.0"),
//
    ],
    targets: [
        .target(
            name: "Harmony",
            dependencies: [
                .product(name: "Roxas", package: "Roxas")
            ],
            resources: [
                .process("Resources"),
            ],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("CoreData")
            ]
        ),
//        .executableTarget(
//            name: "Example",
//            dependencies: ["Harmony", "Roxas", "HarmonyDrive", "HarmonyDropbox"],
//            resources: [
//                .copy("Resources/GoogleService-Info.plist"),
//                .process("Resources/UIKit")
//            ],
//            linkerSettings: [
//                .linkedFramework("UIKit"),
//                .linkedFramework("CoreData")
//            ]
//        ),
        .testTarget(
            name: "HarmonyTests",
            dependencies: ["Harmony"]
        )
    ]
)
