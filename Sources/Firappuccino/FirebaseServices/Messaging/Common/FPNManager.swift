#if !os(macOS)
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

public protocol FPNSendable {
	
}

public class FPNManager: NSObject, FPNSendable, MessagingDelegate, UNUserNotificationCenterDelegate {
	let userID: String
	
	let sender: FPNSendable = Configurator.useLegacyMessaging ? LegacyFPNSender() : FPNSender()
	
	let v1Sender = FPNSender()
	let legacySender = LegacyFPNSender()
	
	public init(userID: String) {
		self.userID = userID
		
		super.init()
	}
	
	public func registerForPushNotifications() async throws {
		
		UNUserNotificationCenter.current().delegate = self
		
		Messaging.messaging().delegate = self
		
		let authOptions: UNAuthorizationOptions = Configurator.authOptions
		
		try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
		
		try await FPNSender.subscribe(to: ["all"])
		
		try await updateFirestorePushTokenIfNeeded()
		
		await UIApplication.shared.registerForRemoteNotifications()
		
		let settings = await UNUserNotificationCenter.current().notificationSettings()
		
		let settingsEnabled = (settings.alertSetting ==
							   UNNotificationSetting.enabled ? "enabled" : "disabled")
		
		let soundEnabled = (settings.soundSetting ==
							UNNotificationSetting.enabled ? "enabled" : "disabled")
		
		Firappuccino.logger.info("Alert setting is \(settingsEnabled)")
		
		Firappuccino.logger.info("Sound setting is \(soundEnabled)")
		
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
		}
	}
	
	func application(_ application: UIApplication,
					 didFailToRegisterForRemoteNotificationsWithError error: Error) {
		Firappuccino.logger.warning("Failed to register for remote notifications with error \(error)")
	}
	
	func application(_ application: UIApplication,
					 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		var readableToken: String = ""
		for i in 0..<deviceToken.count {
			readableToken += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
		}
		Messaging.messaging().apnsToken = deviceToken
		Firappuccino.logger.info("Received an APNs device token: \(readableToken)")
	}
	
	func application(_ application: UIApplication,
					 didReceiveRemoteNotification userInfo: [AnyHashable: Any],
					 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult)
					 -> Void) {
		
		// Print message ID.
		if let messageID = userInfo[Configurator.gcmMessageIDKey] {
			Firappuccino.logger.info("Message ID: \(messageID)")
		}
		
		// Print full message.
		Firappuccino.logger.info("\(userInfo)")
		
		completionHandler(UIBackgroundFetchResult.newData)
	}
	
	public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
		// Note: This callback is fired at each app startup and whenever a new token is generated.
		let fcmToken = Messaging.messaging().fcmToken
		Firappuccino.logger.info("Firebase registration token: \(String(describing: fcmToken))")
		
		let dataDict: [String: String] = ["token": fcmToken ?? ""]
		NotificationCenter.default.post(
			name: Notification.Name("FCMToken"),
			object: nil,
			userInfo: dataDict
		)
	}
}

public extension FPNManager {
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								willPresent notification: UNNotification,
								withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
								-> Void) {
		let userInfo = notification.request.content.userInfo
		
		if let messageID = userInfo[Configurator.gcmMessageIDKey] {
			Firappuccino.logger.info("Message ID: \(messageID)")
		}
		// Print full message.
		Firappuccino.logger.info("\(userInfo)")
		
		// Change this to your preferred presentation option
		completionHandler([[.banner, .sound, .badge, .alert]])
		
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								didReceive response: UNNotificationResponse,
								withCompletionHandler completionHandler: @escaping () -> Void) {
		
		Firappuccino.logger.info("\(response)")
		
		let userInfo = response.notification.request.content.userInfo
		
		// Print full message.
		Firappuccino.logger.info("\(userInfo)")
		
		completionHandler()
	}
}

extension FPNManager {
	/// Triggers the send of a FPNMessage Payload to the specified `FUser`
	/// - Parameters:
	///   - sender: The `FUser` whose in-app action triggered the send.
	///   - recipient: The intended recipient of the `FPNMessage`
	///   - messageBody: The body of the `FPNMessage`
	///   - attachmentImageURL: The `URL` for an optional image attachment
	///   - additionalInfo: Additional descriptive info to include in the `FPNMessage`
	///   - throws: An `NSError`
	public static func sendUserMessage<T, U>(from sender: T, to recipient: U, messageBody: String, attachmentImageURL: URL?, additionalInfo: String?) async throws where T: FUser, U: FUser {
		
		do {
//			let message = FPNMessage("", messageBody: messageBody, sender: sender, category: "all", imageFromURL: attachmentImageURL?.absoluteString, additionalInfo: additionalInfo)
			
			switch Configurator.useLegacyMessaging {
					
				case true:
					// Legacy API
					let message = FPNMessage("", messageBody: messageBody, sender: sender, category: "all", imageFromURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/hilarist-authentication.appspot.com/o/FCMImages%2FHilaristPreviewProfileImage.png?alt=media&token=0d1a5276-4cea-4562-a0d2-c14c5cc6571b")?.absoluteString, additionalInfo: additionalInfo)
					
					try await Firappuccino.sender.send(message, to: recipient, data: ["count": recipient.notifications.filter({ !$0.read }).count])
					
				case false:
					//TODO: - Add a `category` enum
					let message = FPNMessage("", messageBody: messageBody, sender: sender, category: "all", imageFromURL: attachmentImageURL?.absoluteString, additionalInfo: additionalInfo)
					
					try await FPNSender.sendUserActionMessagingNotification(message: message, to: recipient, withData: ["count": recipient.notifications.filter({ !$0.read }).count])
			}
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
}

#endif

