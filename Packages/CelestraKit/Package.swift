// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - Swift Settings Configuration
let swiftSettings: [SwiftSetting] = [
    // Swift 6.2 Upcoming Features (not yet enabled by default)
    .enableUpcomingFeature("ExistentialAny"),                    // SE-0335: Introduce existential `any`
    .enableUpcomingFeature("InternalImportsByDefault"),          // SE-0409: Access-level modifiers on import declarations
    .enableUpcomingFeature("MemberImportVisibility"),            // SE-0444: Member import visibility (Swift 6.1+)
    .enableUpcomingFeature("FullTypedThrows"),                   // SE-0413: Typed throws

    // Experimental Features (stable enough for use)
    .enableExperimentalFeature("BitwiseCopyable"),               // SE-0426: BitwiseCopyable protocol
    .enableExperimentalFeature("BorrowingSwitch"),               // SE-0432: Borrowing and consuming pattern matching for noncopyable types
    .enableExperimentalFeature("ExtensionMacros"),               // Extension macros
    .enableExperimentalFeature("FreestandingExpressionMacros"),  // Freestanding expression macros
    .enableExperimentalFeature("InitAccessors"),                 // Init accessors
    .enableExperimentalFeature("IsolatedAny"),                   // Isolated any types
    .enableExperimentalFeature("MoveOnlyClasses"),               // Move-only classes
    .enableExperimentalFeature("MoveOnlyEnumDeinits"),           // Move-only enum deinits
    .enableExperimentalFeature("MoveOnlyPartialConsumption"),    // SE-0429: Partial consumption of noncopyable values
    .enableExperimentalFeature("MoveOnlyResilientTypes"),        // Move-only resilient types
    .enableExperimentalFeature("MoveOnlyTuples"),                // Move-only tuples
    .enableExperimentalFeature("NoncopyableGenerics"),           // SE-0427: Noncopyable generics
    .enableExperimentalFeature("OneWayClosureParameters"),       // One-way closure parameters
    .enableExperimentalFeature("RawLayout"),                     // Raw layout types
    .enableExperimentalFeature("ReferenceBindings"),             // Reference bindings
    .enableExperimentalFeature("SendingArgsAndResults"),         // SE-0430: sending parameter and result values
    .enableExperimentalFeature("SymbolLinkageMarkers"),          // Symbol linkage markers
    .enableExperimentalFeature("TransferringArgsAndResults"),    // Transferring args and results
    .enableExperimentalFeature("VariadicGenerics"),              // SE-0393: Value and Type Parameter Packs
    .enableExperimentalFeature("WarnUnsafeReflection"),          // Warn unsafe reflection

    // Enhanced compiler checking
    .unsafeFlags([
        "-warn-concurrency",                    // Enable concurrency warnings
        "-enable-actor-data-race-checks",       // Enable actor data race checks
        "-strict-concurrency=complete",         // Complete strict concurrency checking
        "-enable-testing",                      // Enable testing support
        "-Xfrontend", "-warn-long-function-bodies=100",       // Warn about functions with >100 lines
        "-Xfrontend", "-warn-long-expression-type-checking=100" // Warn about slow type checking expressions
    ])
]

let package = Package(
    name: "CelestraKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26),
        .watchOS(.v26),
        .tvOS(.v26),
        .macCatalyst(.v26)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CelestraKit",
            targets: ["CelestraKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/brightdigit/SyndiKit.git", from: "0.6.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CelestraKit",
            dependencies: [
                .product(name: "SyndiKit", package: "SyndiKit"),
                .product(name: "Logging", package: "swift-log")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CelestraKitTests",
            dependencies: ["CelestraKit"],
            swiftSettings: swiftSettings
        ),
    ]
)
