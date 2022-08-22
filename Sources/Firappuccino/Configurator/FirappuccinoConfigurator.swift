import Foundation
import Firebase
import Logging


public struct FirappuccinoConfigurator {
	
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
		FirappuccinoAuth.prepare()
		
		// Logging
		LoggingSystem.bootstrap(FirappuccinoOSLog.init)
		FirappuccinoOSLog.overrideLogLevel = globalOverrideLogLevel
	}
}
