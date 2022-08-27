import SwiftUI
import Firappuccino
import FirebaseAuth
import Logging

class AppDelegate: NSObject, UIApplicationDelegate {
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		
		// Use Legacy Messaging API
		Configurator.useLegacyMessaging = true
		Configurator.legacyMessagingAPIKey = "AAAAAlm70VY:APA91bHReDsmGJIIO2eP1s7ss10mjOzhDGUb0fVIEENPW3s0twlrhhJ64mGSgwnqvLkHGk7BkJkLa9B1_IT6nsUBO58VjvbYTMQtvgrKOHvylFOqbigHOZjbRt2LNbUfoS1zvE1Zv6t4"
		
		// Turn off local cache
		Configurator.useCache = false
			
		// Configurate
		Configurator.configurate(WithOptions: nil, globalOverrideLogLevel: Logger.Level.error)

		// for debug
				UserDefaults.standard.set(false, forKey: Constants.userDefaults.didWalkThroughKey)
		return true
	}
}

@main
struct ExampleApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
	@StateObject var authService = ExampleAuthService.currentSession
	@StateObject var postService = ExamplePostsService()
	
	var body: some Scene {
		WindowGroup {
			NavigationView {
				ContentView()
			}
			.environmentObject(authService)
			.environmentObject(postService)
			.onAppear {
				FAuth.onUserUpdate(ofType: ExampleFUser.self) { user in
					guard let user = user, !user.isDummy else { return }
					if authService.isSigningUp == true {
						user.progress = 0
						Task {
							try await user.updateDisplayName(to: "\(authService.currentUser.firstName) \(authService.currentUser.lastName)", ofUserType: ExampleFUser.self)
						}
					}
					authService.currentUser = user
					authService.isSigningUp = false
					if let userId = Auth.auth().currentUser?.uid {
						authService.pushManager = LegacyFPNManager(userID: userId)
						authService.pushManager?.registerForPushNotifications()
					}
					
					return
				}
			}
		}
	}
}
