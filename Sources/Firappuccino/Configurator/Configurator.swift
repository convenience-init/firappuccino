import Foundation
import Firebase
import Logging


public struct Configurator {
	
	// Cache
	public static var useCache: Bool = true
	
	//Configurator
	@MainActor public static func configurate(WithOptions: FirebaseOptions? = nil, globalOverrideLogLevel: Logger.Level? = nil) {
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
