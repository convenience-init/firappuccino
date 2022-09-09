import Logging
import SwiftUI
import Firappuccino
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		
		// Configurate
		
		/// Configuration
		let exampleAppConfig = Configuration(legacyFPN: true, legacyAPIKey: AppConstants.legacyMessagingAPIKey, imagePath: AppConstants.imagePath, iss: AppConstants.iss, projectName: AppConstants.projectID, privateKey: AppConstants.privateKeyPath, publicKey: AppConstants.publicKeyPath, gcmIdKey: AppConstants.gcmMessageIDKey, clientID: AppConstants.clientID, globalOverrideLogLevel: Logger.Level.error)
		
		Configurator.configurate(configuration: exampleAppConfig)
		
		// for debug
//		UserDefaults.standard.set(false, forKey: AppConstants.userDefaults.didWalkThroughKey)
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
					guard let user = user, !user.isDummy else { return }
					if authService.isSignupComplete == false {
						Task {
							user.progress = 0
							user.firstName = authService.firstName
							user.lastName = authService.lastName
							
							try? await user.updateDisplayName(to: user.firstName, ofUserType: ExampleFUser.self)
							
							try await user.write()
							
							authService.currentUser = user
							authService.firstName = ""
							authService.lastName = ""
							authService.isSignupComplete = true
						}
					}
					else {
						authService.currentUser = user
					}
					
					//FPN Messaging
					if let userId = Auth.auth().currentUser?.uid {
						authService.pushManager = FPNManager(userID: userId)
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

