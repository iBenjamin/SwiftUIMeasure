import ProjectDescription

let project = Project(
    name: "SwiftUIMeasure",
    targets: [
        // Framework
        .target(
            name: "SwiftUIMeasure",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.swiftuimeasure.framework",
            deploymentTargets: .multiplatform(iOS: "18.0", macOS: "15.0"),
            sources: ["Sources/SwiftUIMeasure/**"],
            dependencies: []
        ),
        // Demo App
        .target(
            name: "Demo",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.swiftuimeasure.demo",
            deploymentTargets: .multiplatform(iOS: "18.0", macOS: "15.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": true
                ]
            ]),
            sources: ["Sources/Demo/**"],
            dependencies: [
                .target(name: "SwiftUIMeasure")
            ]
        ),
        // Tests
        .target(
            name: "SwiftUIMeasureTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.swiftuimeasure.tests",
            deploymentTargets: .multiplatform(iOS: "18.0", macOS: "15.0"),
            sources: ["Tests/SwiftUIMeasureTests/**"],
            dependencies: [
                .target(name: "SwiftUIMeasure")
            ]
        )
    ]
)
