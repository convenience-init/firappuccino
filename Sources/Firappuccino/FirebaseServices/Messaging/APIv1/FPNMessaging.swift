import Firebase
import FirebaseMessaging
import SwiftJWT


public struct FPNMessaging {
	
	/// The Relative `URL` `String` path of the ``Google Service Account`` private `._key` file
	public static var privateKeyFilePath: String = ""
	
	/// The Relative `URL` `String` path of the ``Google Service Account`` public `.key` file
	public static var publicKeyFilePath: String = ""
	
	/// The `String` value of issuer property of a `MessageClaim`
	public static var iss: String = ""
	
	/// The Name of the Firebase Project Associated with your App
	public static var projectName: String = ""
	
	/// The OAuth 2.0 Bearer Token generated from public/privavte keypair
	private static var bearerToken: String = ""
	
	/// The URL location of the Google Service Account private `._key` file
	private static var privateKeyPath = URL(fileURLWithPath: privateKeyFilePath).absoluteURL
	
	/// The URL location of the Google Service Account public `.key` file as an absoluteURL`
	private static var publicKeyPath = URL(fileURLWithPath: publicKeyFilePath).absoluteURL
	
	/// Returns the Google Service Account private `._key` file
	private static var privateKey: Data {
		var data: Data = Data()
		do {
			data = try Data(contentsOf: privateKeyPath, options: .alwaysMapped)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
		}
		return data
	}
	
	/// The location of the Google Service Account public key file
	private static var publicKey: Data {
		var data: Data = Data()
		do {
			data = try Data(contentsOf: publicKeyPath, options: .alwaysMapped)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
		}
		return data
	}
	
	/// Returns the user's device token for the current device.
	public static var deviceToken: String? {
		return Messaging.messaging().fcmToken
	}
	
	/// Subscribes the user to the specified topic.
	/// - Parameter topics: The `[String]` names of the topics to subscribe to.
	/// - Throws: An `NSError`
	public static func subscribe(to topics: [String]) async throws {
		for topic in topics {
			do {
				try await Messaging.messaging().subscribe(toTopic: topic)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
	}
	
	/// Unsubscribes the user from the specified topics.
	/// - Parameter topics: The `[String]` names of the topics to unsubscribe from.
	/// Throws: An `NSError`
	public static func unsubscribe(from topics: [String]) async throws {
		for topic in topics {
			do {
				try await Messaging.messaging().unsubscribe(fromTopic: topic)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
	}
	
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
			//FIXME: - Use a category enum and an `allCases` computed property
			let message = FPNMessage("", messageBody: messageBody, sender: sender, category: "all", imageFromURL: attachmentImageURL?.absoluteString, additionalInfo: additionalInfo)
			try await FPNMessaging.sendUserActionMessagingNotification(message: message, to: recipient, withData: ["count": recipient.notifications.filter({ !$0.read }).count])
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	/// Handles the preparation, authentication and sending of the `FPNMessage` to the specified `FUser` via Firebase REST API.
	/// - Parameters:
	///   - message: The `FPNMessage` to send to the recipient `FUser`.
	///   - user: The `FUser` to receive the push `FPNMessage`.
	/// - Throws: An `NSError`
	/// - Note: This will not add a `FPNMessage` object to the user's `FirebaseMessaging` notification list.
	private static func sendUserActionMessagingNotification<T>(message: FPNMessage, to recipient: T, withData messageData: [AnyHashable: Any]) async throws where T: FUser {
		
		async let jwt = try await createMessagingJWT()
		
		let headers = ["Content-Type": "application/x-www-form-urlencoded"]
		
		let postData = NSMutableData(data: "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer".data(using: String.Encoding.utf8)!)
		
		postData.append("&assertion=\(try await jwt)".data(using: String.Encoding.utf8)!)
		
		let request = NSMutableURLRequest(url: NSURL(string: "https://oauth2.googleapis.com/token")! as URL,
										  cachePolicy: .useProtocolCachePolicy,
										  timeoutInterval: 10.0)
		request.httpMethod = "POST"
		request.allHTTPHeaderFields = headers
		request.httpBody = postData as Data
		let session = URLSession.shared
		let dataTask = session.dataTask(with: request as URLRequest) { data, _, _ in
			do {
				if let jsonData = data {
					if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
						print(jsonDataDict)
						self.bearerToken = jsonDataDict["access_token"] as! String
					}
				}
			}
			catch let error as NSError {
				return Firappuccino.logger.error("\(error.localizedDescription)")
				
			}
			
			guard !recipient.disabledMessageCategories.contains(message.category) else {
				return Firappuccino.logger.warning("Message not sent because the user has disabled the '`\(message.category)' category.")
				
			}
			
			Task {
				do {
					try await sendNotificationTo(recipient, title: message.title, body: message.pushBody, imageURL: message.image, bearerToken: bearerToken, data: messageData)
				}
				catch let error as NSError {
					Firappuccino.logger.error("\(error.localizedDescription)")
					throw error
				}
			}
		}
		dataTask.resume()
	}
	
	/// Creates a signed `JWT` from the private `._key` file to request a `Bearer` scoped to `firebase.messaging` that is then passed to ```sendNotificationTo(_:title:body:imageURL:bearerToken:data:)```.
	/// - Returns: A `JWT` as a base64 encoded `String` or a thrown `Error`
	/// - Throws: An `NSError`
	/// - Warning: Must set FPNMessaging.iss static property in AppDelegate before using `FPNMessaging`
	private static func createMessagingJWT() async throws -> String {
		
		guard !iss.isEmpty else {
			Firappuccino.logger.critical("Message not sent because no issuer was provided - The `URL` for the `iss` property has not been set.")
			return ""
		}
		
		let claims = FPNMessagingJWTClaim(iss: iss, scope: "https://www.googleapis.com/auth/firebase.messaging", aud: "https://oauth2.googleapis.com/token", exp: Date(timeIntervalSinceNow: 3600), iat: Date())
		
		var messageJWT = JWT(claims: claims)
		let jwtSigner = JWTSigner.rs256(privateKey: privateKey)
		let signedJWT = try messageJWT.sign(using: jwtSigner)
		return signedJWT
	}
	
	/// Requests a `bearerToken` using the passed in `JWT`
	/// - Returns: A `String` Bearer token that will be passed into ```sendNotificationTo(_:title:body:imageURL:bearerToken:data:)```.
	/// - Throws: An `NSError`
	private static func getBearerToken() async throws -> String {
		async let jwt = try await createMessagingJWT()
		var bearer = ""
		let headers = ["Content-Type": "application/x-www-form-urlencoded"]
		
		let postData = NSMutableData(data: "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer".data(using: String.Encoding.utf8)!)
		
		postData.append("&assertion=\(try await jwt)".data(using: String.Encoding.utf8)!)
		
		let request = NSMutableURLRequest(url: NSURL(string: "https://oauth2.googleapis.com/token")! as URL,
										  cachePolicy: .useProtocolCachePolicy,
										  timeoutInterval: 10.0)
		request.httpMethod = "POST"
		request.allHTTPHeaderFields = headers
		request.httpBody = postData as Data
		
		let session = URLSession.shared
		let dataTask = session.dataTask(with: request as URLRequest) { data, _, _ in
			do {
				if let jsonData = data {
					if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
						print(jsonDataDict)
						bearer = jsonDataDict["access_token"] as! String
					}
				}
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
			}
		}
		dataTask.resume()
		return bearer
	}
	
	
	/// Sends a `POST` request to `FirebaseMessaging` REST API to trigger the notification send
	/// - Parameters:
	///   - recipient: The `FUser` who is the recipient of the notification
	///   - title: The title of the notification
	///   - body: The body of the notification
	///   - bearerToken: The `bearerToken` to authenticate the `POST` request
	///   - data: The supplemental data to send with the notification, i.e.
	///   ````["count": user.notifications.filter({ !$0.read }).count]````
	/// - Throws: An `NSError`
	private static func sendNotificationTo<T>(_ recipient: T, title: String = "", body: String, imageURL: String?, bearerToken: String, data: [AnyHashable: Any] = [:]) async throws where T: FUser {
		
		guard let deviceToken = recipient.deviceToken else {
			return Firappuccino.logger.critical("No device token found for user \(recipient)")
		}
		
		var postData: Data
		
		let headers = [
			"Content-Type": "application/json",
			"Authorization": "Bearer \(bearerToken)"
		]
		
		var parameters = ["message": [
			"token": "\(deviceToken)",
			"notification": [
				"title": "\(title)",
				"body": "\(body)",
			]
		]] as [String : Any]
		
		if let imageURL = imageURL, !imageURL.isEmpty {
			parameters = ["message": [
				"token": "\(deviceToken)",
				"notification": [
					"title": "\(title)",
					"body": "\(body)",
					"image": "\(imageURL)"
				]
			]] as [String : Any]
		}
		
		do {
			let data = try JSONSerialization.data(withJSONObject: parameters, options: [])
			postData = data
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
		let request = NSMutableURLRequest(url: NSURL(string: "https://fcm.googleapis.com/v1/projects/"+projectName+"/messages:send")! as URL,
										  cachePolicy: .useProtocolCachePolicy,
										  timeoutInterval: 10.0
		)
		request.httpMethod = "POST"
		request.allHTTPHeaderFields = headers
		request.httpBody = postData as Data
		let session = URLSession.shared
		let dataTask = session.dataTask(with: request as URLRequest) { data, _, _ in
			do {
				if let jsonData = data {
					if let jsonDataDict = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
						Firappuccino.logger.info("Received data:\n\(jsonDataDict))")
					}
				}
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
			}
		}
		dataTask.resume()
		Firappuccino.logger.info("Message '\(title)' sent!")
	}
}
