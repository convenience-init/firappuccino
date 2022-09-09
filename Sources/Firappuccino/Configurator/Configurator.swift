import Foundation
import Firebase
import FirebaseMessaging
import Logging


public struct Configuration {
	public let legacyFPN: Bool
	public let legacyAPIKey: String?
	public let imagePath: String?
	public let iss: String?
	public let projectName: String
	public let privateKey: String?
	public let publicKey: String?
	public let gcmIdKey: String
	public let clientID: String
	public let withFirebaseOptions: FirebaseOptions?
	public let globalOverrideLogLevel: Logger.Level?
	
	
	public init(legacyFPN: Bool, legacyAPIKey: String? = nil, imagePath: String? = nil, iss: String? = nil, projectName: String, privateKey: String? = nil, publicKey: String? = nil, gcmIdKey: String, clientID: String, withFirebaseOptions: FirebaseOptions? = nil, globalOverrideLogLevel: Logger.Level? = nil) {
		self.legacyFPN = legacyFPN
		self.legacyAPIKey = legacyAPIKey
		self.imagePath = imagePath
		self.iss = iss
		self.projectName = projectName
		self.privateKey = privateKey
		self.publicKey = publicKey
		self.gcmIdKey = gcmIdKey
		self.clientID = clientID
		self.withFirebaseOptions = withFirebaseOptions
		self.globalOverrideLogLevel = globalOverrideLogLevel
	}
}


/// Configuration for Firappuccino and Firebase services
public struct Configurator {
	
	public static var configuration: Configuration? = nil
	
	/// Configures Firebase and Firappuccino
	/// - Parameters:
	///   - WithOptions: The FirebaseOptions, if any, to use in configuration
	///   - globalOverrideLogLevel: An optional global override of the default `Logger.Level` for unified logging
	public static func configurate(configuration: Configuration? = nil) {
		guard let configuration = configuration else {
			return
		}
		
		self.configuration = configuration
		
		// FirebaseApp
		if let options = configuration.withFirebaseOptions {
			FirebaseApp.configure(options: options)
		}
		else {
			FirebaseApp.configure()
		}
		
		// Auth
		FAuth.prepare(with: configuration.clientID)
		
		// Unified Logging
		LoggingSystem.bootstrap(FOSLog.init)
		FOSLog.overrideLogLevel = configuration.globalOverrideLogLevel
		
		// APIv1 Cloud Messaging
		if !configuration.legacyFPN {
			
			FPNSender.iss = configuration.iss ?? ""
			
			FPNSender.projectName = configuration.projectName
			
			FPNSender.privateKeyFilePath = configuration.privateKey ?? ""
			
			FPNSender.publicKeyFilePath = configuration.publicKey ?? "" 
		}
	}
}
