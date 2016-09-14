import PackageDescription

let package = Package(
    name: "CSH-Link",
    dependencies: [
        .Package(url: "https://github.com/vapor/sqlite-provider.git", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 0, minor: 18)
    ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources",
        "Tests",
    ]
)
