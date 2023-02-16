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
        .executable(name: "HarmonyExample", targets: ["HarmonyExample"]),
    ],
    dependencies: [
         .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: Version("2.0.0")),
         .package(url: "https://github.com/JoeMatt/Roxas.git", from: "1.2.0")
//        .package(path: "../Roxas")
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
            name: "HarmonyExample",
			dependencies: [ "Harmony", "HarmonyTestData",
							.product(name: "RoxasUI", package: "Roxas", condition: .when(platforms: [.iOS, .tvOS, .macCatalyst]))],
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
