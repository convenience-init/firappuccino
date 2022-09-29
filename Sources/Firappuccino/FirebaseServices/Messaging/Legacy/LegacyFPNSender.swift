import Foundation
#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

public final class LegacyFPNSender: FPNSendable {
	/*
	 The `FUser` recipient must have a `deviceToken` property available in their user object. The `deviceToken` is automatically generated upon login, uploaded to Firestore, and managed by `FPNManager`.
	 
	 - parameter notification: The notification to send to the user.
	 - parameter user: The user to send the notification to.
	 */
	public func send<T>(_ notification: FPNMessage, to user: T, data: [AnyHashable: AnyHashable] = ["count": 0]) async throws where T: FUser {
		guard !user.disabledMessageCategories.contains(notification.category) else {
			return Firappuccino.logger.warning("Message not sent because the recipient has the message category '`\(notification.category)' disabled.")
			
		}
		sendNotification(to: user, title: "", body: notification.pushBody, data: data)
	}
	
	private func sendNotification<T>(to user: T, title: String, body: String, data: [AnyHashable: Any] = [:]) where T: FUser {
		guard let legacyKey = Configurator.configuration?.legacyAPIKey, !legacyKey.isEmpty else {
			return Firappuccino.logger.critical("No Legacy MessagingAPI Key has been set! Ensure that `Configurator.legacyMessagingAPIKey` is set before using Legacy API Messaging.")
			
		}
		guard let token = user.deviceToken else {
			return Firappuccino.logger.critical("Could not retrieve a device token for user \(user).")
			
		}
		let urlString = "https://fcm.googleapis.com/fcm/send"
		let url = NSURL(string: urlString)!
		
		let paramString: [String: Any] = ["to": token,
										  "notification":
											[
												"title": title,
												"body": body
											],
										  "data": data,
										  "priority": "high"
		]
		let request = NSMutableURLRequest(url: url as URL)
		request.httpMethod = "POST"
		request.httpBody = try? JSONSerialization.data(withJSONObject: paramString, options: [.prettyPrinted])
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("key=\(legacyKey)", forHTTPHeaderField: "Authorization")
		let task = URLSession.shared.dataTask(with: request as URLRequest) { data, _, _ in
			do {
				if let jsonData = data {
					if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
						Firappuccino.logger.info("Received data:\n\(jsonDataDict))")
					}
				}
			}
			catch let error as NSError {
				return Firappuccino.logger.error("\(error.localizedDescription)")
				
			}
		}
		task.resume()
		Firappuccino.logger.info("Message '\(title)' sent!")
	}
	
	public init(){}
}
