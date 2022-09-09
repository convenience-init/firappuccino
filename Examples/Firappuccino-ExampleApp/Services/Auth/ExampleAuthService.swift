import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore
import FirebaseAuth
import Combine
import Firappuccino

final class ExampleAuthService: ObservableObject {
	static let currentSession = ExampleAuthService()
	
	@Published var user: User?
	@Published var currentUser: ExampleFUser
	@Published var pushManager: FPNManager?
	@Published var error: NSError?
	// Signup Form
	@Published var firstName: String = ""
	@Published var lastName: String = ""
	
	private var authenticationStateHandler: AuthStateDidChangeListenerHandle?
	
	init() {
		currentUser = ExampleFUser()
	}
	
	@Published var isAuthenticating = false
	@Published var isSigningUp = false
	
	@Published var isSignupComplete: Bool = true
	
	@MainActor func login(with loginOption: LoginOption) async throws {
		
		self.isAuthenticating = true
		
		self.isSigningUp = false
		
		self.error = nil
		
		switch loginOption {
				
			case .signInWithApple:
				try await FAuth.signInWithApple()
				self.isAuthenticating = false
				
			case .signInWithGoogle:
				do {
					try await FAuth.signInWithGoogle(clientID: AppConstants.clientID)
					self.isAuthenticating = false
				}
				catch let error as NSError {
					Firappuccino.logger.error("\(error.localizedDescription)")
					throw error
				}
				
			case let .emailAndPassword(email, password):
				
				do {
					try await FAuth.signIn(email: email, password: password)
					self.isAuthenticating = false
				}
				catch let error as NSError {
					Firappuccino.logger.error("\(error.localizedDescription)")
					throw error
				}
		}
	}
	
	func signout() async throws {
		do {
			try await FAuth.signOut()
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	  @MainActor func signup(email: String, firstName: String, lastName: String, password: String, passwordConfirmation: String) async throws {
		
		guard password == passwordConfirmation else {
			let error = NSError(domain: "xyz.firappuccino.ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: "Password and confirmation does not match"])
			Firappuccino.logger.warning("\(error.localizedDescription)")
			self.error = error
			throw error
		}
		
		isAuthenticating = true
		isSigningUp = true
		isSignupComplete = false
		error = nil
		
		do {
			try await FAuth.createAccount(email: email, password: password)
			self.isAuthenticating = false
			self.isSigningUp = false
			self.isSignupComplete = false
			self.error = nil
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	func sendEmailVerification() async throws {
		do {
			try await currentUser.refreshEmailVerificationStatus()
			try await currentUser.sendEmailVerification()
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	func updatePassword(to newPassword: String) async throws {
		do {
			try await currentUser.updatePasswordTo(newPassword: newPassword)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	func sendPasswordReset(to email: String) async throws {
		do {
			try await currentUser.sendPasswordReset()
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	func updateEmail(to email: String) async throws {
		do {
			try await currentUser.updateEmail(to: email, ofUserType: ExampleFUser.self)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	
	func updateProfile() async throws {
		do {
			try await currentUser.write()
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	///- warning: You MUST implement a confirmation Alert in your app if you want the user to be informed before this destructive action!
	@MainActor func remove() async throws {
		
		do {
			try await Firappuccino.Destroyer.`destroy`(currentUser)
		}
		catch let error as NSError {
			throw error
		}
		try await Firappuccino.Destroyer.`destroy`(currentUser)
	}
}
