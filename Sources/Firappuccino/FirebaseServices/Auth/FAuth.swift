import UIKit
import Combine
import Firebase
import FirebaseAuth
import Logging
import AuthenticationServices

public class FAuth: NSObject {
	
	public typealias DefaultURL = String
	
	public enum DefaultImageURL: DefaultURL, CaseIterable, Codable {
		case profile = "https://firebasestorage.googleapis.com/v0/b/hilarist-authentication.appspot.com/o/FCMImages%2FHilaristPreviewProfileImage.png?alt=media&token=0d1a5276-4cea-4562-a0d2-c14c5cc6571b"
		
	}
	public static var defaultProfileImageURL: URL = URL(string: DefaultImageURL.profile.rawValue)!
	
	public internal(set) static var emailVerified: Bool = false
	
	public internal(set) static var accountProvider: Provider = .unknown
	
	public internal(set) static var authHandle: AuthStateDidChangeListenerHandle?
	
	public static var signedIn: Bool {
		return Auth.auth().currentUser != nil
	}
	
	internal static let auth = Auth.auth()
	
	internal static let listenerKey: Firappuccino.ListenerKey = "F_USER_CHANGE"
	
	internal var currentNonce: String?
	
	/**
	 Create a new `FirebaseAuth` account using email authorization flow.
	 
	 - Important: You will need to implement input validation yourself.
	 - parameter email: The email to associate with the account.
	 - parameter password: The password for the account.
	 */
	public static func createAccount(email: String, password: String) async throws {
		
		do {
			let authResult = try await auth.createUser(withEmail: email, password: password)
			try await handleAuthResult(authResult: authResult, error: nil)
		}
		catch let error as NSError {
			try await handleAuthResult(authResult: nil, error: error)
		}
	}
	
	/// Signs-in a registered `FUser` using a registered `FirebaseAuth` account and the `Provider.email` `accountProvider`.
	/// - Parameters:
	///   - email: The user's registered account email address
	///   - password: The user's account password
	public static func signIn(email: String, password: String) async throws {
		
		accountProvider = .email
		
		do {
			
			let authResult = try await auth.signIn(withEmail: email, password: password)
			
			try await handleAuthResult(authResult: authResult, error: nil)
		}
		catch {
			try await handleAuthResult(authResult: nil, error: error)
		}
	}
	
	/// Signs a `FUser` into a registered `FirebaseAuth` account using the specified credentials.
	/// - Parameter credential: The appropriate `AuthCredential` for the desired authorization flow.
	/// - Note: Do not call this method directly if using "SignIn with Apple" or "Google SignIn" - call the appropriate convenience methods,
	///
	///```signInWithApple()```,
	///```signInWithGoogle(clientID:)```, or
	///```signInWithGoogle(clientID:secret:)```
	/// instead.
	public static func signIn(with credential: AuthCredential) async throws {
		
		do {
			async let authResult = try await auth.signIn(with: credential)
			try await handleAuthResult(authResult: try await authResult, error: nil)
		}
		catch let error {
			Firappuccino.logger.error("\(error.localizedDescription)")
			try? await handleAuthResult(authResult: nil, error: error)
		}
	}
	
	/// Signs the currently logged-in `FUser` out of all services.
	public static func signOut() throws {
		//TODO: - badge count reset
		
		do {
			try auth.signOut()
		}
		catch let error as NSError {
			Firappuccino.logger.error( "\(error.localizedDescription)")
		}
	}
	
	/// Allows you to specify actions to perform on the user object the user is updated.
	/// - Parameters:
	///   - type: The `Type` of your custom `FUser` object or subclass
	///   - action: A closure containing the actions to perform when the the `FUser` object changes.
	@MainActor public static func onUserUpdate<T>(ofType type: T.Type, perform action: @escaping (T?) -> Void) where T: FUser {
		if let authHandle = authHandle {
			auth.removeStateDidChangeListener(authHandle)
		}
		authHandle = auth.addStateDidChangeListener { _, user in
			Task {
				guard let user = user, let newUser = await T.get(from: user), !newUser.isDummy else { return }
				Firappuccino.Listen.stop(listenerKey)
				Firappuccino.Listen.`listen`(to: newUser.id, ofType: T.self, key: listenerKey) { document in
					guard let document = document else {
						action(newUser)
						Task {try? await newUser.`write`()}
						return
					}
					action(document)
				}
			}
		}
	}
	
	/// Checks to see if a username is unique in your `FUser` objects collection in `Firestore`.
	/// - Parameters:
	///   - username: The username to query for.
	///   - forUserType: The user `Type` to query against.
	/// - Returns: A `Bool`, `true` if the passed `username` is unique, `false` otherwise.
	public static func isUsernameAvailable<T>(_ username: String, forUserType: T.Type) async throws -> Bool where T: FUser {
		let path: KeyPath<T, String> = \.username
		return try await Firappuccino.FQuery.wherePath(path, .equals, username).count<=0
	}
	
	/// Prepares GoogleAppAuth
	internal static func prepare() {
		GAppAuth.shared.appendAuthorizationRealm(OIDScopeEmail)
		GAppAuth.shared.retrieveExistingAuthorizationState()
	}
	
	/// Handles the authorization flow for ``Google SignIn``
	/// - Parameter credential: The credential to use for the Auth request.
	internal static func handleGoogleSignInCredential(credential: AuthCredential?) async throws {
		
		guard let credential = credential else {
			Firappuccino.logger.error("\(NoCredentialError())")
			throw NoCredentialError()
		}
		
		do {
			try await FAuth.signIn(with: credential)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	/// Provides a callback to execute code actions when `AuthState` changes.
	/// - Parameter action: A closure containing the code to execute after this method is called.
	@available(*, renamed: "onAuthChange()")
	@MainActor internal static func onAuthChange<T>(perform action: @escaping (T?) -> Void) where T: FUser {
		
		if let authHandle = authHandle {
			auth.removeStateDidChangeListener(authHandle)
		}
		authHandle = auth.addStateDidChangeListener { _, user in
			Task {
				guard let user = user, let newUser = await T.get(from: user) else { return }
				guard let document = try await Firappuccino.Fetch.`fetch`(id: newUser.id, ofType: T.self) else { return try await newUser.`write`()
				}
				action(document)
			}
		}
	}
	
	@MainActor internal static func onAuthChange<T>() async -> T? where T: FUser {
		return await withCheckedContinuation { continuation in
			onAuthChange() { result in
				continuation.resume(returning: result)
			}
		}
	}
	
	
	/// Handles the `FAuth` authentication result
	/// - Parameters:
	///   - authResult: An optional `AuthDataResult` or `nil`
	///   - error: An optional `Error` or `nil`
	/// - Throws: An `Error`
	internal static func handleAuthResult(authResult: AuthDataResult?, error: Error?) async throws {
		
		if let error = error {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
		else if let authResult = authResult {
			let user = authResult.user
			emailVerified = user.isEmailVerified
			
			if let provider = Provider(rawValue: authResult.credential?.provider ?? "Unknown") {
				accountProvider = provider
			}
		}
	}
	
	/// The Available Account Providers
	public enum Provider: String, Codable {
		case unknown = "Unknown"
		case apple = "Apple"
		case google = "Google"
		case email = "Email"
		
		init(provider: String) {
			switch provider {
				case "apple.com": self = .apple
				case "google.com": self = .google
				default: self = .email
			}
		}
	}
	
	internal class NoCredentialError: LocalizedError {
		var errorDescription: String? = "No credential found."
	}
}

#if os(iOS)
extension FAuth {
	
	/// ``Google SignIn`` Authentication Flow (iOS)
	/// - Parameter clientID: The `ClientID` for your project/app
	/// - Throws: An `Error`
	/// - Remark: If you have not yet created ClientID, go to the [Google Cloud Developer Console](https://console.cloud.google.com/apis/dashboard) > Credentials > Create Credentials > OAuth Client ID and create one for your iOS application.
	/// - Important: Do not include the `apps.googleusercontent.com` portion of your `ClientID`. It should be strictly alphanumeric, and contain no punctuation except dashes, i.e. ```xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx```
	public static func signInWithGoogle(clientID: String) async throws {
		let _clientID = "\(clientID).apps.googleusercontent.com"
		let redirectURI = "com.googleusercontent.apps.\(clientID):/oauthredirect"
		accountProvider = .google
		do {
			async let credential = getCredential(clientID: _clientID, redirectUri: redirectURI)
			try await handleGoogleSignInCredential(credential: try await credential)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	/// Gets a ``Google SignIn`` `AuthCredential` provided valid `clientID` and `redirecUri`
	/// - Parameters:
	///   - clientID: The `ClientID` to use for the request
	///   - redirectUri: The `RedirectURI` to use for the request
	/// - Returns: An optional `AuthCredential?` or `nil`
	/// - Throws: An `Error`
	private static func getCredential(clientID: String, redirectUri: String) async throws -> AuthCredential? {
		var credential: AuthCredential?
		do {
			try await GAppAuth.shared.authorize(in: UIApplication.shared.windows.first!.rootViewController!, clientID: clientID, redirectUri: redirectUri) { _ in
				guard
					GAppAuth.shared.isAuthorized(),
					let authorization = GAppAuth.shared.getCurrentAuthorization(),
					let accessToken = authorization.authState.lastTokenResponse?.accessToken,
					let idToken = authorization.authState.lastTokenResponse?.idToken
				else { return }
				credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
			}
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
		return credential
	}
}

#elseif os(macOS)
import Cocoa
import AppKit

extension FAuth {
	
	/// ``Google SignIn`` Authentication Flow (macOS)
	/// - Parameters:
	///   - clientID: The `ClientID` for your project/app
	///   - secret: The secret to use for the call
	/// - Throws: An `Error`
	/// - Remark: If you have not yet created ClientID, go to the [Google Cloud Developer Console](https://console.cloud.google.com/apis/dashboard) > Credentials > Create Credentials > OAuth Client ID and create one for a Web application. The other fields are optional, and can be left empty.
	/// - Important: Do not include the `apps.googleusercontent.com` portion of your `ClientID`. It should be strictly alphanumeric, and contain no punctuation except dashes, i.e. ```xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx```
	public static func signInWithGoogle(clientID: String, secret: String) async throws {
		let _clientID = "\(clientID).apps.googleusercontent.com"
		let redirectURI = "com.googleusercontent.apps.\(clientID):/oauthredirect"
		accountProvider = .google
		do {
			async let credential = getCredential(clientID: _clientID, redirectUri: redirectURI, secret: secret)
			try await handleGoogleSignInCredential(credential: try await credential)
		}
		catch let error as NSError {
			Firappuccino.logger.error(error.localizedDescription)
			throw error
		}
	}
	
	/// Handles a redirectURI after completed sign-in from the user's browser.
	/// - Parameter event: An `NSAppleEventDescriptor` to handle
	/// In your `AppDelegate.swift`, implement `applicationDidFinishLaunching(_:)`:
	///
	///	```
	///	func applicationDidFinishLaunching(_ aNotification: Notification){
	///	NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
	///}
	///```
	///	*Using the SwiftUI lifecycle? See [this discussion](https://developer.apple.com/forums/thread/659537#answer-title) *.*
	///In `AppDelegate.swift`, add an Objective-C exposed method ```handleEvent(event:replyEvent:)```:
	///```
	///@objc private func handleEvent(event: NSAppleEventDescriptor, replyEvent:NSAppleEventDescriptor) {
	///FAuth.handle(event: event)
	///}
	///```
	/// `FAuth` will handle the remaining flow after ```handle(event:)``` is called.
	public static func handle(event: NSAppleEventDescriptor) async {
		let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue ?? ""
		let url = URL(string: urlString)!
		_ = GoogleAppAuth.shared.continueAuthorization(with: url, callback: nil)
	}
	
	private static func getCredential(clientID: String, redirectUri: String, secret: String) async throws -> AuthCredential? {
		var authCred: AuthCredential? = nil
		do {
			async let _ = try GoogleAppAuth.shared.authorize(clientID: clientID, clientSecret: secret, redirectUri: redirectUri, callback: nil)
			
			async let authorization = GoogleAppAuth.shared.getCurrentAuthorization()
			if let accessToken = await authorization?.authState.lastTokenResponse?.accessToken, let idToken = await authorization?.authState.lastTokenResponse?.idToken {
				let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
				authCred = credential
			}
		}
		catch let error as NSError {
			FirappuccinoConfigurator.logger.error(error.localizedDescription)
			throw error
		}
		return authCred
	}
}
#endif

extension FAuth: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
	
	private static var shared = FAuth()
	
	/**
	 Signs in with Apple.
	 
	 In order for this sign-in method to work on your target, you'll need to configure SignIn with Apple to work on your Xcode project.
	 
	 1. Join the [Apple Developer Program](https://developer.apple.com/programs/).
	 2. Enable Sign In with Apple on your app on the [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources) page of Apple's developer site by going to More > Configure > Add Email Source. Add your website domain under **Domains and Subdomains**, and add `noreply@YOUR_FIREBASE_PROJECT_ID.firebaseapp.co` under **Email Addressess**.
	 3. Add the **Sign In with Apple** capability to your project.
	 
	 In SwiftUI, create the Sign In with Apple button. Call ``signInWithApple()`` within the `onRequest` block:
	 
	 ```swift
	 import AuthenticationServices
	 
	 // ...
	 
	 SignInWithAppleButton(onRequest: { _ in
	 FAuth.signInWithApple()
	 }, onCompletion: { _ in })
	 ```
	 */
	public static func signInWithApple() {
		let nonce = String.nonce()
		shared.currentNonce = nonce
		accountProvider = .apple
		let appleIDProvider = ASAuthorizationAppleIDProvider()
		let request = appleIDProvider.createRequest()
		request.requestedScopes = [.fullName, .email]
		request.nonce = nonce.sha256()
		let authorizationController = ASAuthorizationController(authorizationRequests: [request])
		authorizationController.delegate = shared
		authorizationController.presentationContextProvider = shared
		authorizationController.performRequests()
	}
	
	/**
	 The presentation anchor implementation for `ASAuthorizationControllerDelegate`.
	 
	 - important: You do not need to call this method. You can override it to customize the view controller for which Sign In with Apple appears, if you'd like.
	 */
	@MainActor public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
#if os(iOS)
		return ASPresentationAnchor()
#elseif os(macOS)
		return NSApplication.shared.windows.first!
#endif
	}
	
	/**
	 Handles a successful ``SignIn with Apple`` authorization flow.
	 
	 - important: It is not necessary to call this method, but you can override it to handle a success state on your own if you'd like.
	 
	 - parameter controller: The authorization controller that just completed
	 - parameter authorization: The ``SignIn with Apple`` authorization
	 */
	public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
		if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
			guard let nonce = currentNonce else {
				fatalError("Invalid state: A login callback was received, but no login request was sent.")
			}
			guard let appleIDToken = appleIDCredential.identityToken else {
				Firappuccino.logger.error("Unable to fetch identity token")
				return
			}
			guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
				Firappuccino.logger.error("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
				return
			}
			let credential = OAuthProvider.credential(
				withProviderID: "apple.com",
				idToken: idTokenString,
				rawNonce: nonce
			)
			
			Task {
				do {
					try await FAuth.signIn(with: credential)
				}
				catch let error as NSError {
					Firappuccino.logger.error("\(error.localizedDescription)")
				}
			}
		}
	}
	
	/**
	 Handles a failed ``SignIn with Apple`` authorization flow.
	 
	 - important:  It is not necessary to call this method, but you can override it to handle a failure state on your own if you'd like.
	 
	 - parameter controller: The authorization controller that just completed
	 - parameter error: The error that occured during the process
	 */
	public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
		Firappuccino.logger.error("Sign in with Apple error: \(error.localizedDescription)")
	}
}

