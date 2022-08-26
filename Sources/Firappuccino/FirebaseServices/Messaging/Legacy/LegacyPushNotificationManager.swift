import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications

class LegacyPushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
	let userID: String
	init(userID: String) {
		self.userID = userID
		super.init()
	}
	
	func registerForPushNotifications() {
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
		if let token = Messaging.messaging().fcmToken {
			let usersRef = Firestore.firestore().collection("users_table").document(userID)
			usersRef.setData(["fcmToken": token], merge: true)
		}
	}
	
	func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
		updateFirestorePushTokenIfNeeded()
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		print(response)
	}
}
