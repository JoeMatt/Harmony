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
        .executable(name: "Example", targets: ["Example"])
    ],
    dependencies: [
         .package(url: "https://github.com/JoeMatt/Roxas.git", from: "1.0.2"),
//        .package(path: "../Roxas")
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
        .target(
            name: "Example",
            dependencies: ["Roxas"]
        ),
        .testTarget(
            name: "HarmonyTests",
            dependencies: ["Harmony"]
        )
    ]
)
