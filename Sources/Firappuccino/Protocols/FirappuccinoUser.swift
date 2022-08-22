import Foundation
import FirebaseAuth
import FirebaseFirestore
import Logging

public protocol FirappuccinoUser: ObservableObject, IndexedFirappuccinoDocument {
	
	var notifications: [FPNMessage] { get set }
	
	var disabledMessageCategories: [FPNMessageCategory] { get set }
	
	var progress: Int { get set }
	
	var deviceToken: String? { get set }
	
	var appVersion: String { get set }
	
	var lastSignon: Date { get set }
	
	var email: String { get set }
	
	var profileImageURL: String? { get set }
	
	var username: String { get set }
	
	var displayName: String { get set }
	
	var index: Int? { get set }
	
	var id: String { get set }
	
	var dateCreated: Date { get set }
	
	var isGuestUser: Bool { get }
	
	static var defaultSuggestionGenerator: (String) -> String { get }
	
	var authUser: User? { get }
	
	static func get(from user: User) async -> Self? where Self: FirappuccinoUser
	
	func updateEmail<T>(to newEmail: String, ofUserType type: T.Type) async throws where T: FirappuccinoUser
	
	func safelyUpdateUsername<T>(to newUsername: String, ofType type: T.Type, suggesting suggestionGenerator: @escaping (String) -> String) async throws -> String where T: FirappuccinoUser
	
	func unsafelyUpdateUsername<T>(to newUsername: String, ofUserType type: T.Type) async throws where T: FirappuccinoUser
	
	func updateDisplayName<T>(to newName: String, ofUserType type: T.Type) async throws where T: FirappuccinoUser
	
	func updatePhoto<T>(with url: URL, ofUserType type: T.Type) async throws where T: FirappuccinoUser
	
	func updatePhoto<T>(with data: Data, ofUserType type: T.Type, progress: @escaping (Double) -> Void) async throws where T: FirappuccinoUser
	
	func updatePasswordTo(newPassword: String) async throws
	
	func sendEmailVerification() async throws
	
	func refreshEmailVerificationStatus() async throws
	
	func sendPasswordReset() async throws
	
	func delete<T>(ofUserType type: T.Type) async throws where T: FirappuccinoUser
	
	func getUniqueUsername(base: String, using generator: @escaping (String) -> String) async throws -> String
	
	func assertAuthMatches() -> Bool
	
	init()
}

// Default Implementation
public extension FirappuccinoUser {
	init(id: String = "guest_user", dateCreated: Date = Date(), deviceToken: String = "-", lastSignon: Date = Date(), email: String = "guest@firappuccino.xyz", username: String = "guest_user", displayName: String = "guest_user", profileImageURL: String = FirappuccinoAuth.defaultProfileImageURL.absoluteString) {
		self.init()
		self.id = id
		self.dateCreated = dateCreated
		self.deviceToken = deviceToken
		self.appVersion = Bundle.versionString
		self.lastSignon = lastSignon
		self.email = email
		self.username = username
		self.displayName = displayName
		self.profileImageURL = profileImageURL
	}
	
	@MainActor static func get(from user: User) async -> Self? where Self: FirappuccinoUser {
		guard let email = user.email else { return nil }
		let newUser = Self()
		
		do {
			newUser.id = user.uid
			newUser.dateCreated = Date()
			newUser.deviceToken = FPNMessaging.deviceToken
			newUser.appVersion = Bundle.versionString
			newUser.lastSignon = Date()
			newUser.email = email
			newUser.username = try email.getEmailPrefix()
			if newUser.username.count < 6 {
				newUser.username += String.random(length: 6 - newUser.username.count)
			}
			newUser.displayName = try user.displayName ?? newUser.email.getEmailPrefix()
			newUser.profileImageURL = user.photoURL?.absoluteString ?? FirappuccinoAuth.defaultProfileImageURL.absoluteString
			await newUser.updateAnalyticsUserProperties()
			try await newUser.refreshEmailVerificationStatus()
			
		}
		catch {
			Firappuccino.logger.error("\(error.localizedDescription)")
		}
		return newUser
	}
	
	/// The default random username suggestion generator.
	static var defaultSuggestionGenerator: (String) -> String {{ username in
		let randomInt = Int.random(in: 0...99)
		return "\(username)\(randomInt)"
	}}
	
	
	/// Returns true if the user is authenticated, otherwise false.
	var isGuestUser: Bool {
		return id == "guest_user"
	}
	
	/**
	 Updates the current `FIRUser`s email address.
	 
	 - parameter newEmail: The new email to update with.
	 - parameter type: The `FirappuccinoUser` object's Type .
	 
	 - note: Updates the email of both the `Firestore User` object and the the custom `FirappuccinoUser` user object.
	 - throws: An `Error`
	 */
	@MainActor func updateEmail<T>(to newEmail: String, ofUserType type: T.Type) async throws where T: FirappuccinoUser {
		guard assertAuthMatches(), let authUser = authUser else {
			return Firappuccino.logger.error("Error: Authentication Mismatch.")
		}
		
		do {
			try await authUser.updateEmail(to: newEmail)
			email = newEmail
			try await set(field: "email", using: \.email, ofType: T.self)
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	/**
	 Updates the `FirappuccinoUser`'s username.
	 
	 - note: This method is *safe*, meaning that it won't update the username if it already exists in your user objects collection.
	 
	 - warning: If you wish to update the user's username regardless of whether it is unique, use ``unsafelyUpdateUsername(to:ofUserType:)``.
	 
	 - important: If the return `String` value is `nil`, it indicates that the username was successfully updated. If a non-`nil` value is returned, it indicates that the username was *not* updated - and instead a suggested username is returned as the value).
	 
	 - remark:  The `suggestionGenerator` parameter allows you to customize a random username to *suggest* based on the new username provided. For instance, if the username `atreyu2000` is unavailable, the generator can be customized to procure a new username `atreyu2000123`. If a random username is generated and is *still* taken, the generator will re-apply to the username previously generated (recursively).
	 
	 If no generator is provided, the default generator will append a random integer `0-99` to the end of the passed-in username.
	 
	 - Note: The suggested username returned updated to be the user's new username when this method is called. Rather, it allows you to provide the user with the suggestion such that they can change it if they like.
	 
	 # Example
	 
	 ```
	 do {
	 if let suggestion = try await user.safelyUpdateUsername(to: "atreyu2000", ofUserType: ExampleFirappUser.self,
	 suggesting: { "\($0)\(Int.random(in: 0...999))" }) == nil {
	 print("Username successfully changed to: \(to)")
	 }
	 else {
	 print("Username taken. Try \(try await suggestion) instead, or choose another.")
	 }
	 }
	 catch let error {
	 throw error
	 }
	 
	 ```
	 
	 - parameter newUsername: The username to update to.
	 - parameter type: The type of the user.
	 - parameter suggestionGenerator: A function that takes in a username and provides a new, unique username.
	 */
	@MainActor func safelyUpdateUsername<T>(to newUsername: String, ofType type: T.Type, suggesting suggestionGenerator: @escaping (String) -> String = defaultSuggestionGenerator) async throws -> String where T: FirappuccinoUser {
		var suggestedName: String = ""
		async let isAvailable = try await FirappuccinoAuth.isUsernameAvailable(newUsername, forUserType: T.self)
		
		if try await isAvailable {
			try await self.unsafelyUpdateUsername(to: newUsername, ofUserType: T.self)
		}
		else {
			async let suggestion = try await self.getUniqueUsername(base: newUsername, using: suggestionGenerator)
			suggestedName = try await suggestion
		}
		return suggestedName
	}
	
	/**
	 Updates the `FirappuccinoUser`'s `username` property.
	 
	 - Warning: This method is *unsafe*, meaning that it will update the username regardless of whether the `username` is unique or not.
	 
	 If you wish to update the `FirappuccinoUser`'s `username` if it is available and provide a suggested username upon failure, instead impelment
	 ````
	 safelyUpdateUsername(to:ofType:suggesting:)
	 ````
	 
	 - parameter newUsername: The username to update to.
	 - parameter type: The type of the user.
	 */
	@MainActor func unsafelyUpdateUsername<T>(to newUsername: String, ofUserType type: T.Type) async throws where T: FirappuccinoUser {
		let oldUsername = username
		self.username = newUsername
		
		do {
			try await set(field: "username", using: \.username, ofType: T.self)
		}
		catch let error as NSError {
			self.username = oldUsername
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	/**
	 Updates the value of the current `FirappuccinoUser`'s `displayName` property.
	 
	 - parameter newName: The new display name to update with.
	 - parameter type: The type of the user.
	 */
	@MainActor func updateDisplayName<T>(to newName: String, ofUserType type: T.Type) async throws where T: FirappuccinoUser {
		guard assertAuthMatches(), let authUser = authUser else { return }
		do {
			async let changeRequest = authUser.createProfileChangeRequest()
			await changeRequest.displayName = newName
			try await changeRequest.commitChanges()
			self.displayName = newName
			try await set(field: "displayName", using: \.displayName, ofType: T.self)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
		}
	}
	
	/**
	 Updates the value of the current `FirappuccinoUser`'s `profileImageURL` property.
	 
	 - parameter url: The new photo URL to update with.
	 - parameter type: The type of the user.
	 */
	@MainActor func updatePhoto<T>(with url: URL, ofUserType type: T.Type) async throws where T: FirappuccinoUser {
		guard assertAuthMatches(), let authUser = authUser else { return }
		do {
			let changeRequest = authUser.createProfileChangeRequest()
			changeRequest.photoURL = url
			try await changeRequest.commitChanges()
			self.profileImageURL = url.absoluteString
			try await Firappuccino.db.collection(String(describing: type)).document(self.id).updateData(["profileImageURL": url.absoluteString])
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	/**
	 Updates profile Image at the current `FirappuccinoUser`'s existing `profileImageURL` with new image data.
	 
	 - parameter data: The data of the new photo to update with.
	 - parameter type: The type of the user.
	 */
	
	@MainActor func updatePhoto<T>(with data: Data, ofUserType type: T.Type, progress: @escaping (Double) -> Void = { _ in }) async throws where T: FirappuccinoUser {
		guard assertAuthMatches() else { return }
		let url = await FirappuccinoResourceStore.put(data, to: FirappuccinoStorageResource(id: id, folder: "ProfileImages"), progress: progress)
		guard let url = url else { return }
		try await updatePhoto(with: url, ofUserType: type)
	}
	
	/**
	 Updates the current `FirappuccinoUser`'s password.
	 
	 - parameter newPassword: The new password to update with.
	 */
	@MainActor func updatePasswordTo(newPassword: String) async throws {
		guard assertAuthMatches(), let authUser = authUser else { return }
		do {
			try await authUser.updatePassword(to: newPassword)
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	/**
	 Sends an email verification on the current user's behalf.
	 
	 - parameter completion: The completion handler.
	 */
	
	func sendEmailVerification() async throws {
		guard assertAuthMatches(), let authUser = authUser else { return }
		do {
			try await authUser.sendEmailVerification()
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	/**
	 Refreshes the `emailVerified` static property of `FirappuccinoAuth`.
	 */
	func refreshEmailVerificationStatus() async throws {
		guard assertAuthMatches(), let authUser = authUser else { return }
		
		do {
			try await authUser.reload()
			guard let user = Auth.auth().currentUser else { return }
			FirappuccinoAuth.emailVerified = user.isEmailVerified
			let id = user.providerData.first?.providerID ?? ""
			FirappuccinoAuth.accountProvider = FirappuccinoAuth.Provider(provider: id)
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	/**
	 Send a password reset request to the associated email.
	 
	 - parameter email: The email to send the password reset request to.
	 */
	func sendPasswordReset() async throws {
		guard assertAuthMatches(), let authUser = authUser, let email = authUser.email else { return }
		do {
			try await Auth.auth().sendPasswordReset(withEmail: email)
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
		
	}
	
	/**
	 Deletes the current user.
	 
	 - warning: This method will *not* ask for confirmation before destroying the user record. You must alert the user from within your app!
	 
	 - parameter type: The type of the user
	 */
	
	@MainActor func delete<T>(ofUserType type: T.Type) async throws where T: FirappuccinoUser {
		guard assertAuthMatches(), let authUser = authUser else { return }
		Firappuccino.Listen.stop(FirappuccinoAuth.listenerKey)
		
		do {
			try await authUser.delete()
			try await Firappuccino.Trash.remove(id: self.id, ofType: T.self)
			try FirappuccinoAuth.signOut()
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	//	func delete<T>(ofUserType type: T.Type, completion: @escaping (Error?) -> Void = { _ in }) where T: FirappuccinoUser {
	//		guard assertAuthMatches() else { return }
	//		if let authUser = authUser {
	//			Firappuccino.Listen.stop(FirappuccinoAuth.listenerKey)
	//			authUser.delete { error in
	//				if let error = error {
	//					completion(error)
	//					return
	//				}
	//				Firappuccino.Trash.remove(id: self.id, ofType: T.self, completion: completion)
	//				DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
	//					try? FirappuccinoAuth.signOut()
	//				}
	//			}
	//		}
	//	}
	
	var authUser: User? {
		Auth.auth().currentUser
	}
	
	func getUniqueUsername(base: String, using generator: @escaping (String) -> String) async throws -> String {
		let new = generator(base)
		do {
			let available = try await FirappuccinoAuth.isUsernameAvailable(new, forUserType: Self.self)
			return available ? new : try await self.getUniqueUsername(base: new, using: generator)
			
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
			throw error
		}
	}
	
	/// A method to check the current `FirappuccinoUser` object matches the `Auth.auth().currentUser` by comparing their respective identifiers
	/// - Returns: A `Bool`: `true` if authentication matches, otherwise `false`
	func assertAuthMatches() -> Bool {
		guard let id = authUser?.uid else {
			return false
		}
		return id == self.id
	}
}



