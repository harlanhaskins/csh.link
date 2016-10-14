import PackageDescription

let package = Package(
    name: "CSH-Link",
    dependencies: [
        .Package(url: "https://github.com/stormpath/Turnstile.git", majorVersion: 1),
        .Package(url: "https://github.com/harlanhaskins/Turnstile-CSH.git", majorVersion: 0),
        .Package(url: "https://github.com/vapor/postgresql-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 1),
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
