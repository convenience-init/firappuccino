import Logging
import SwiftUI
import Firappuccino
import FirebaseAuth
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		// Legacy Messaging API
		Configurator.useLegacyMessaging = true
		Configurator.legacyMessagingAPIKey = AppConstants.legacyMessagingAPIKey

		// Configurate
		Configurator.configurate(globalOverrideLogLevel: Logger.Level.error)

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

extension AppDelegate {
	// Receive displayed notifications for iOS 10 devices.
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								willPresent notification: UNNotification,
								withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
								-> Void) {
		let userInfo = notification.request.content.userInfo

		if let messageID = userInfo[AppConstants.gcmMessageIDKey] {
			print("Message ID: \(messageID)")
		}
		// Print full message.
		print(userInfo)

		// Change this to your preferred presentation option
		completionHandler([[.banner, .sound, .badge, .alert]])

	}

	func userNotificationCenter(_ center: UNUserNotificationCenter,
								didReceive response: UNNotificationResponse,
								withCompletionHandler completionHandler: @escaping () -> Void) {
		let userInfo = response.notification.request.content.userInfo

		// Print full message.
		Firappuccino.logger.info("\(userInfo)")

		completionHandler()
	}
}
