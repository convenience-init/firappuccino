import Foundation
import Firebase
import FirebaseMessaging
import Logging


/// Configuration for Firappuccino and Firebase services
public struct Configurator {
	
	// Legacy Cloud Messaging API
	public static var useLegacyMessaging = false
	public static var legacyMessagingAPIKey = ""
	
	// Cloud Messaging
	public static let gcmMessageIDKey = "gcm.message_id"
	
	/// Configures Firebase and Firappuccino
	/// - Parameters:
	///   - WithOptions: The FirebaseOptions, if any, to use in configuration
	///   - globalOverrideLogLevel: An optional global override of the default `Logger.Level` for unified logging
	  public static func configurate(WithOptions: FirebaseOptions? = nil, globalOverrideLogLevel: Logger.Level? = nil) {
		
		  // FirebaseApp
		if let options = WithOptions {
			FirebaseApp.configure(options: options)
		}
		else {
			FirebaseApp.configure()
		}
		
		// Auth
		FAuth.prepare()
		
		// Unified Logging
		LoggingSystem.bootstrap(FOSLog.init)
		FOSLog.overrideLogLevel = globalOverrideLogLevel
	}
}
