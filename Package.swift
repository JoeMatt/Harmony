// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Harmony",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .macCatalyst(.v13),
		.macOS(.v12)
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
         .package(url: "https://github.com/JoeMatt/Roxas.git", from: "1.1.1"),
         .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: Version("2.0.0"))
         //        .package(path: "../Roxas")
         // Technically, example needs this, but results in circular include
//         .package(url: "https://github.com/JoeMatt/Harmony-Drive.git", from: "1.0.0"),
//
    ],
    targets: [
        .target(
            name: "Harmony",
            dependencies: [
                .product(name: "Roxas", package: "Roxas")
            ],
            resources: [
                .process("Resources/"),
            ],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("CoreData")
            ]
        ),
		// Tests
		.target(
			name: "HarmonyTestData",
			dependencies: ["Harmony"],
			resources: [
				.process("Resources/")
			]
	   ),
        .executableTarget(
            name: "Example",
            dependencies: [ "Harmony", "HarmonyTestData" ],
            resources: [
                .copy("Resources/GoogleService-Info.plist"),
                .process("Resources/UIKit")
            ],
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("CoreData")
            ]
        ),
        .testTarget(
            name: "HarmonyTests",
            dependencies: ["Harmony", "CwlPreconditionTesting", "HarmonyTestData"]
        )
    ],
	swiftLanguageVersions: [.v5]
)
