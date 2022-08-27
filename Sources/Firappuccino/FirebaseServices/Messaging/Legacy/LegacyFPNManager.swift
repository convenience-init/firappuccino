import UIKit
import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

public class LegacyFPNManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
	let userID: String
	let sender = LegacyFPNSender()
	
	public init(userID: String) {
		self.userID = userID
		super.init()
	}
	
	@MainActor public func registerForPushNotifications() {
			UNUserNotificationCenter.current().delegate = self
			let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
			UNUserNotificationCenter.current().requestAuthorization(
				options: authOptions,
				completionHandler: {_, _ in })

			Messaging.messaging().delegate = self

		UIApplication.shared.registerForRemoteNotifications()
		updateFirestorePushTokenIfNeeded()
	}
	
	func updateFirestorePushTokenIfNeeded() {
		if let fcmToken = Messaging.messaging().fcmToken {
			print("Firebase registration token: \(String(describing: fcmToken))")
			
			let dataDict: [String: String] = ["token": fcmToken ]
			NotificationCenter.default.post(
				name: Notification.Name("FCMToken"),
				object: nil,
				userInfo: dataDict
			)
			
//			let usersRef = Firestore.firestore().document(userID)
//			usersRef.setData(["deviceToken": fcmToken], merge: true)
		}
	}
	
	public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
		updateFirestorePushTokenIfNeeded()
	}
	
	public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		print(response)
	}
}
