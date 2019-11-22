// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LibzipSwift",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9),
        .macOS(.v10_10),
        .watchOS(.v2),
    ],
    products: [
        .library(name: "zip", targets: ["zip"]),
        .library(name: "LibzipSwift", targets: ["LibzipSwift"]),
    ],
    targets: [
        .target(
            name: "zip",
            path: "Sources/zip",
            exclude: [
                // Exclude BZ2 compression
                "libzip/lib/zip_algorithm_bzip2.c",
                "libzip/lib/zip_algorithm_xz.c",
                
                // Exclude non-CommonCrypto encryption
                "libzip/lib/zip_crypto_gnutls.c",
                "libzip/lib/zip_crypto_mbedtls.c",
                "libzip/lib/zip_crypto_openssl.c",
                "libzip/lib/zip_crypto_win.c",
                
                // Exclude Windows random
                "libzip/lib/zip_random_win32.c",
                "libzip/lib/zip_random_uwp.c",
                
                // Exclude Windows utilities
                "libzip/lib/zip_source_win32a.c",
                "libzip/lib/zip_source_win32handle.c",
                "libzip/lib/zip_source_win32utf8.c",
                "libzip/lib/zip_source_win32w.c",
                "libzip/lib/zip_source_winzip_aes_decode.c",
                "libzip/lib/zip_source_winzip_aes_encode.c",
                "libzip/lib/zip_winzip_aes.c",
                
            ],
            sources: [
                "libzip/lib",
            ],
            publicHeadersPath: "include",
            cSettings: [
                .define("HAVE_CONFIG_H"),
                .headerSearchPath("libzip/xcode"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
            ]
        ),
        .target(
            name: "LibzipSwift",
            dependencies: ["zip"],
            path: "Sources/LibzipSwift"
        ),
        .testTarget(
            name: "LibzipSwiftTests",
            dependencies: ["LibzipSwift"]),
    ]
)
