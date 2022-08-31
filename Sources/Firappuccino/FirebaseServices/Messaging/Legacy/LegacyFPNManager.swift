import UIKit
import FirebaseMessaging
import UserNotifications

public class LegacyFPNManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
	let userID: String
	let sender = LegacyFPNSender()
	
	public init(userID: String) {
		self.userID = userID
		super.init()
	}
	
	@MainActor public func registerForPushNotifications() async throws {
		UNUserNotificationCenter.current().delegate = self
		let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
		try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
		
		Messaging.messaging().delegate = self
		
		UIApplication.shared.registerForRemoteNotifications()
		try await updateFirestorePushTokenIfNeeded()
	}
	
	func updateFirestorePushTokenIfNeeded() async throws {
		if let fcmToken = Messaging.messaging().fcmToken {
			print("Firebase registration token: \(String(describing: fcmToken))")
			
			let dataDict: [String: String] = ["token": fcmToken ]
			NotificationCenter.default.post(
				name: Notification.Name("FCMToken"),
				object: nil,
				userInfo: dataDict
			)
			if var user = try? await Firappuccino.Fetcher.fetch(id: userID, ofType: FUserBase.self) {
				try await user.write(value: fcmToken, using: \FUserBase.deviceToken)
			}
		}
	}
	
	public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
		Task {
			try? await updateFirestorePushTokenIfNeeded()
		}
	}
	
	public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		print(response)
	}
}
