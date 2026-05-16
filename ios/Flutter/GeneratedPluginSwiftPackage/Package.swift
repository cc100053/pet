// swift-tools-version: 5.9
// This tracked package mirrors FlutterGeneratedPluginSwiftPackage, but keeps
// the package platform aligned with Firebase iOS SDK 12.x requirements.

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "url_launcher_ios", path: "../ephemeral/Packages/.packages/url_launcher_ios"),
        .package(name: "shared_preferences_foundation", path: "../ephemeral/Packages/.packages/shared_preferences_foundation"),
        .package(name: "path_provider_foundation", path: "../ephemeral/Packages/.packages/path_provider_foundation"),
        .package(name: "app_links", path: "../ephemeral/Packages/.packages/app_links"),
        .package(name: "share_plus", path: "../ephemeral/Packages/.packages/share_plus"),
        .package(name: "purchases_ui_flutter", path: "../ephemeral/Packages/.packages/purchases_ui_flutter"),
        .package(name: "purchases_flutter", path: "../ephemeral/Packages/.packages/purchases_flutter"),
        .package(name: "package_info_plus", path: "../ephemeral/Packages/.packages/package_info_plus"),
        .package(name: "in_app_review", path: "../ephemeral/Packages/.packages/in_app_review"),
        .package(name: "image_picker_ios", path: "../ephemeral/Packages/.packages/image_picker_ios"),
        .package(name: "image_cropper", path: "../ephemeral/Packages/.packages/image_cropper"),
        .package(name: "google_mobile_ads", path: "../ephemeral/Packages/.packages/google_mobile_ads"),
        .package(name: "webview_flutter_wkwebview", path: "../ephemeral/Packages/.packages/webview_flutter_wkwebview"),
        .package(name: "flutter_timezone", path: "../ephemeral/Packages/.packages/flutter_timezone"),
        .package(name: "flutter_local_notifications", path: "../ephemeral/Packages/.packages/flutter_local_notifications"),
        .package(name: "sqflite_darwin", path: "../ephemeral/Packages/.packages/sqflite_darwin"),
        .package(name: "firebase_messaging", path: "../ephemeral/Packages/.packages/firebase_messaging"),
        .package(name: "firebase_core", path: "../ephemeral/Packages/.packages/firebase_core"),
        .package(name: "firebase_crashlytics", path: "../ephemeral/Packages/.packages/firebase_crashlytics"),
        .package(name: "firebase_analytics", path: "../ephemeral/Packages/.packages/firebase_analytics"),
        .package(name: "emoji_picker_flutter", path: "../ephemeral/Packages/.packages/emoji_picker_flutter"),
        .package(name: "audioplayers_darwin", path: "../ephemeral/Packages/.packages/audioplayers_darwin")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "app-links", package: "app_links"),
                .product(name: "share-plus", package: "share_plus"),
                .product(name: "purchases-ui-flutter", package: "purchases_ui_flutter"),
                .product(name: "purchases-flutter", package: "purchases_flutter"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "in-app-review", package: "in_app_review"),
                .product(name: "image-picker-ios", package: "image_picker_ios"),
                .product(name: "image-cropper", package: "image_cropper"),
                .product(name: "google-mobile-ads", package: "google_mobile_ads"),
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview"),
                .product(name: "flutter-timezone", package: "flutter_timezone"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-crashlytics", package: "firebase_crashlytics"),
                .product(name: "firebase-analytics", package: "firebase_analytics"),
                .product(name: "emoji-picker-flutter", package: "emoji_picker_flutter"),
                .product(name: "audioplayers-darwin", package: "audioplayers_darwin")
            ]
        )
    ]
)
