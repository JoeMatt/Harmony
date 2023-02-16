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
				.linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
				.linkedFramework("AppKit", .when(platforms: [.macOS])),
				.linkedFramework("Cocoa", .when(platforms: [.macOS])),
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
		// TODO: Make internal targets for UIKit resources and then conditionally depend @JoeMatt
		.target(
			name: "HarmonyExample-iOS",
			resources: [
				.process("Resources/")
			]
		),
		.target(
			name: "HarmonyExample-tvOS",
			resources: [
				.process("Resources/")
			]
		),
		.target(
			name: "HarmonyExample-macOS",
			resources: [
				.process("Resources/")
			]
		),
        .executableTarget(
            name: "HarmonyExample",
			dependencies: [
				"Harmony",
				"HarmonyTestData",
				.target(name: "HarmonyExample-iOS", condition: .when(platforms: [.iOS, .macCatalyst])),
				.target(name: "HarmonyExample-tvOS", condition: .when(platforms: [.tvOS])),
				.target(name: "HarmonyExample-macOS", condition: .when(platforms: [.macOS])),
				.product(name: "RoxasUI", package: "Roxas", condition: .when(platforms: [.iOS, .tvOS, .macCatalyst]))
			],
            resources: [
                .copy("Resources/GoogleService-Info.plist")
            ],
            linkerSettings: [
				.linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
				.linkedFramework("AppKit", .when(platforms: [.macOS])),
				.linkedFramework("Cocoa", .when(platforms: [.macOS])),
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
