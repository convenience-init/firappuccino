import SwiftUI
import Firappuccino
import FirebaseAuth
import Logging

class AppDelegate: NSObject, UIApplicationDelegate {
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		
		// Use Legacy Messaging API
		Configurator.useLegacyMessaging = true
		Configurator.legacyMessagingAPIKey = AppConstants.legacyMessagingAPIKey
		// Turn off local fCache
//		Configurator.useCache = false
		
		// Configurate
		Configurator.configurate(WithOptions: nil, globalOverrideLogLevel: Logger.Level.error)
		
		// for debug
						UserDefaults.standard.set(false, forKey: AppConstants.userDefaults.didWalkThroughKey)
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
				FAuth.onAuthStateChanged(ofType: ExampleFUser.self) { user in
					guard var user = user, !user.isDummy else { return }
					if authService.isSignupComplete == false {
						Task {
							user.progress = 0
							user.firstName = authService.firstName
							user.lastName = authService.lastName
							
							try? await user.updateDisplayName(to: user.firstName, ofUserType: ExampleFUser.self)
							
							try await user.writeAndIndex()
							
							authService.currentUser = user
							authService.firstName = ""
							authService.lastName = ""
							authService.isSignupComplete = true
						}
					}
					else {
						authService.currentUser = user
					}
					
					//Legacy FPN Messaging
					if let userId = Auth.auth().currentUser?.uid {
						authService.pushManager = LegacyFPNManager(userID: userId)
						Task {
							try? await authService.pushManager?.registerForPushNotifications()
						}
					}
					return
				}
			}
		}
	}
}
