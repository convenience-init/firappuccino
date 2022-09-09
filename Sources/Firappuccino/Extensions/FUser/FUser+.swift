import FirebaseAnalytics
import FirebaseAnalyticsSwift
import FirebaseAuth

public extension FUser {
	
	/// The analytics User Properties for a `FUser` object.
	/// - Returns: A `Dictionary` containing data to send to Firebase Analytics when a `FUser` opens the application.
	/// - Note: When creating your own objects by subclassing `FBaseUser` convenience class or by the adopting the `FUser` directly, this property can be overridden to specify custom User properties to include in Firebase Analytics. These `FUser` properties are automatically updated each time your app is opened.
	func analyticsProperties() -> [String: String] {
		return ["progress": "\(progress)", "app_version": appVersion]
	}
	
	/// Sends the `FUser` object's analytics properties to Firebase Analytics.
	func updateAnalyticsUserProperties() async {
		for key in analyticsProperties().keys {
			FAnalytics.`write`(String(key), value: analyticsProperties()[key])
		}
	}
}

// Default Protocol Implementation
public extension FUser {
	init(id: String = "dummy", dateCreated: Date = Date(), deviceToken: String = "", lastSignon: Date = Date(), email: String = "", username: String = "", displayName: String = "", profileImageURL: String = FAuth.defaultProfileImageURL.absoluteString) {
		self.init()
		self.id = id
		self.createdAt = dateCreated
		self.deviceToken = deviceToken
		self.appVersion = Bundle.versionString
		self.lastSignon = lastSignon
		self.email = email
		self.username = username
		self.displayName = displayName
		self.profileImageURL = profileImageURL
	}
	
	  @MainActor static func get(from user: User) -> Self? {
		guard let email = user.email else { return nil }
		let newUser = Self()
		
		do {
			newUser.id = user.uid
			newUser.createdAt = Date()
			newUser.deviceToken = FPNSender.deviceToken
			newUser.appVersion = Bundle.versionString
			newUser.lastSignon = Date()
			newUser.email = email
			newUser.username = try email.getEmailPrefix()
			if newUser.username.count < 6 {
				newUser.username += String.random(length: 6 - newUser.username.count)
			}
			newUser.displayName = try user.displayName ?? newUser.email.getEmailPrefix()
			newUser.profileImageURL = user.photoURL?.absoluteString ?? FAuth.defaultProfileImageURL.absoluteString
			Task {
				await newUser.updateAnalyticsUserProperties()
				try await newUser.refreshEmailVerificationStatus()
			}
		}
		catch {
			Firappuccino.logger.error("\(error.localizedDescription)")
		}
		return newUser
	}
	
	static var defaultSuggestionGenerator: (String) -> String {{ username in
		let randomInt = Int.random(in: 0...99)
		return "\(username)\(randomInt)"
	}}
	
	var isDummy: Bool {
		return id == "dummy"
	}
	
	func updateEmail<T>(to newEmail: String, ofUserType type: T.Type) async throws where T: FUser {
		guard assertAuthMatches(), let authUser = authUser else {
			return Firappuccino.logger.error("Error: Authentication Mismatch.")
		}
		
		do {
			try await authUser.updateEmail(to: newEmail)
			self.email = newEmail
			try await self.`updateRemoteField`(with: newEmail, using: \.email)

		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	func safelyUpdateUsername<T>(to newUsername: String, ofUserType type: T.Type, suggesting suggestionGenerator: @escaping (String) -> String = defaultSuggestionGenerator) async throws -> String where T: FUser {
		var suggestedName: String = ""
		if try await FAuth.isUsernameAvailable(newUsername, forUserType: T.self) {
			try await self.unsafelyUpdateUsername(to: newUsername, ofUserType: T.self)
		}
		else {
			let suggestion = try await getUniqueUsername(base: newUsername, using: suggestionGenerator)
			suggestedName = suggestion
		}
		return suggestedName
	}
	
	func unsafelyUpdateUsername<T>(to newUsername: String, ofUserType type: T.Type) async throws where T: FUser {
		let oldUsername = username
		self.username = newUsername
		
		do {
			try await self.`updateRemoteField`(with: newUsername, using: \.username)
		}
		catch let error as NSError {
			self.username = oldUsername
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	func updateDisplayName<T>(to newName: String, ofUserType type: T.Type) async throws where T: FUser {
		guard assertAuthMatches(), let authUser = authUser else { return }
		do {
			let changeRequest = authUser.createProfileChangeRequest()
			changeRequest.displayName = newName
			try await changeRequest.commitChanges()
			self.displayName = newName
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
		}
	}
	
	func updatePhoto<T>(with url: URL, ofUserType type: T.Type) async throws where T: FUser {
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
	
	func updatePhoto<T>(with data: Data, ofUserType type: T.Type, progress: @escaping (Double) -> Void = { _ in }) async throws where T: FUser {
		guard assertAuthMatches() else { return }
		let url = await FirappuccinoResourceStore.put(data, to: FirappuccinoStorageResource(id: id, folder: "ProfileImages"), progress: progress)
		guard let url = url else { return }
		try await updatePhoto(with: url, ofUserType: type)
	}
	
	  func updatePasswordTo(newPassword: String) async throws {
		guard assertAuthMatches(), let authUser = authUser else { return }
		do {
			try await authUser.updatePassword(to: newPassword)
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	  func sendEmailVerification() async throws {
		guard assertAuthMatches(), let authUser = authUser else { return }
		do {
			try await authUser.sendEmailVerification()
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	  func refreshEmailVerificationStatus() async throws {
		guard assertAuthMatches(), let authUser = authUser else { return }
		
		do {
			try await authUser.reload()
			guard let user = Auth.auth().currentUser else { return }
			FAuth.emailVerified = user.isEmailVerified
			let id = user.providerData.first?.providerID ?? ""
			FAuth.accountProvider = FAuth.Provider(provider: id)
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	  func sendPasswordReset() async throws {
		guard assertAuthMatches(), let authUser = authUser, let email = authUser.email else { return }
		do {
			try await Auth.auth().sendPasswordReset(withEmail: email)
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
		
	}
	
	  func `destroy`<T>(ofUserType type: T.Type) async throws where T: FUser {
		guard assertAuthMatches(), let authUser = authUser else { return }
		Firappuccino.Listener.stop(FAuth.listenerKey)
		
		do {
			try await authUser.delete()
			try await Firappuccino.Destroyer.`destroy`(id: self.id, ofType: T.self)
			try await FAuth.signOut()
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	var authUser: User? {
		Auth.auth().currentUser
	}
	
	  func getUniqueUsername(base: String, using generator: @escaping (String) -> String) async throws -> String {
		let new = generator(base)
		do {
			let available = try await FAuth.isUsernameAvailable(new, forUserType: Self.self)
			return available ? new : try await self.getUniqueUsername(base: new, using: generator)
			
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
			throw error
		}
	}
	
	func assertAuthMatches() -> Bool {
		guard let id = authUser?.uid else {
			return false
		}
		return id == self.id
	}
}

