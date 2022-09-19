// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Firappuccino",
	platforms: [.macOS(.v11),
		.iOS(.v14),
		.watchOS(.v7),
	],
	products: [
		
		.library(
			name: "Firappuccino",
			targets: ["Firappuccino"]),
	],
	dependencies: [
		
		.package(url: "https://github.com/firebase/firebase-ios-sdk", .upToNextMajor(from: "8.0.0")),
		.package(url: "https://github.com/google/GTMAppAuth.git", from: "1.0.0"),
		.package(url: "https://github.com/openid/AppAuth-iOS.git", .upToNextMajor(from: "1.4.0")),
		.package(url: "https://github.com/Kitura/Swift-JWT.git", .upToNextMajor(from: "3.6.201")),
		.package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
	],
	targets: [
		
		.target(
			name: "Firappuccino",
			dependencies: [
				.product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
				.product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
				.product(name: "FirebaseFirestoreSwift-Beta", package: "firebase-ios-sdk"),
				.product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
				.product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
				.product(name: "FirebaseStorageSwift-Beta", package: "firebase-ios-sdk"),
				.product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
				.product(name: "FirebaseAnalyticsSwift-Beta", package: "firebase-ios-sdk"),
				.product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
				.product(name: "FirebaseFunctionsSwift-Beta", package: "firebase-ios-sdk"),
				.product(name: "GTMAppAuth", package: "GTMAppAuth"),
				.product(name: "AppAuth", package: "AppAuth-iOS"),
				.product(name: "SwiftJWT", package: "Swift-JWT"),
				.product(name: "Logging", package: "swift-log"),
			]),
//			.testTarget(
//				name: "FirappuccinoTests",
//				dependencies: ["Firappuccino"]),
	]
)
