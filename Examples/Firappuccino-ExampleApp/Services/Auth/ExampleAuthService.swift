import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore
import Combine
import Firappuccino

enum LoginOption {
	case signInWithGoogle
	case signInWithApple
	case emailAndPassword(email: String, password: String)
}

enum AuthenticationType: String {
	case login
	case signup
	
	var text: String {
		rawValue.capitalized
	}
	
	var assetBackgroundName: String {
		self == .login ? "login" : "login"
	}
	
	var footerText: String {
		switch self {
			case .login:
				return "Not a member, signup"
				
			case .signup:
				return "Already a member? login"
		}
	}
}


final class ExampleAuthService: ObservableObject {
	static let currentSession = ExampleAuthService()
	
	@Published var user: User?
	@Published var currentUser: ExampleFUser
	@Published var pushManager: LegacyFPNManager?
	@Published var error: NSError?
	
	private var authenticationStateHandler: AuthStateDidChangeListenerHandle?
	
	init() {
		currentUser = ExampleFUser()
	}
	
	@Published var isAuthenticating = false
	@Published var isSigningUp = false
	
	func login(with loginOption: LoginOption) throws {
		
	Task {
		DispatchQueue.main.async {
			self.isAuthenticating = true
			self.isSigningUp = false
			ExampleAuthService.currentSession.isSigningUp = false
			self.error = nil
		}
		
		switch loginOption {
				
			case .signInWithApple:
				FAuth.signInWithApple()
				self.isAuthenticating = false
				
			case .signInWithGoogle:
				do {
					try await FAuth.signInWithGoogle(clientID: AppConstants.ClientId)
					DispatchQueue.main.async {
						self.isAuthenticating = false
					}
				}
				catch let error as NSError {
					Firappuccino.logger.error("\(error.localizedDescription)")
					throw error
				}
				
			case let .emailAndPassword(email, password):
				
				do {
					try await FAuth.signIn(email: email, password: password)
					DispatchQueue.main.async {
						self.isAuthenticating = false
					}
				}
				catch let error as NSError {
					Firappuccino.logger.error("\(error.localizedDescription)")
					throw error
				}
		}
		}
	}
	
	func signout() throws {
		do {
			try FAuth.signOut()
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	func signup(email: String, firstName: String, lastName: String, password: String, passwordConfirmation: String) throws {
		Task {
		guard password == passwordConfirmation else {
			let error = NSError(domain: "xyz.firappuccino.ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: "Password and confirmation does not match"])
			Firappuccino.logger.warning("\(error.localizedDescription)")
			self.error = error
			throw error

			}
		
			DispatchQueue.main.async { [self] in
		isAuthenticating = true
		isSigningUp = true
		ExampleAuthService.currentSession.isSigningUp = true
		error = nil
		}
		do {
			try await FAuth.createAccount(email: email, password: password)
			DispatchQueue.main.async {
				self.isAuthenticating = false
				self.error = nil
			}
			DispatchQueue.main.async {self.isSigningUp = false}
			
		}
		catch let error {
			throw NSError(domain: "xyz.firappuccino.ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
		}
		}
	}
	
	func sendEmailVerification() throws {
		Task {
//			guard let currentUser = currentUser else {
//			return
//		}
		
		try await currentUser.refreshEmailVerificationStatus()
		try await currentUser.sendEmailVerification()
			
		}
	}
	
	func updatePassword(to newPassword: String) throws {
		Task {
//			guard let currentUser = currentUser else {
//			return
//		}
		try await currentUser.updatePasswordTo(newPassword: newPassword)}
	}
	
	func sendPasswordReset(to email: String) throws {
		Task {
//			guard let currentUser = currentUser else {
//			return
//		}
		try await currentUser.sendPasswordReset()
		}
	}
	
	func updateEmail(to email: String) throws {
		Task {
//			guard let currentUser = currentUser else {
//			return
//		}
		
		do {
			try await currentUser.updateEmail(to: email, ofUserType: ExampleFUser.self)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
		}
	}
	
	
	func updateProfile() throws {
		Task {
//			guard let currentUser = currentUser else {
//			return
//		}
		do {
			try await currentUser.write()
		}
		catch let error {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
			}
		}
	}
	
	func remove() throws {
		//TODO: - Implement Confirmation Alert
		Task {
//			guard let currentUser = currentUser else {
//			return
//		}
		do {
			try await Firappuccino.Trash.remove(currentUser)
		}
		catch let error {
			throw NSError(domain: "xyz.firappuccino.ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
		}
		try await Firappuccino.Trash.remove(currentUser)
		}
	}
}
