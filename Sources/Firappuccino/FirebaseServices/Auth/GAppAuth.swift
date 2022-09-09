@_exported import AppAuth
@_exported import GTMAppAuth

#if os(iOS)
import UIKit
/// Wrapper class that provides convenient AppAuth functionality with Google Services.
/// Set `ClientId`, `RedirectUri` and call respective methods where you need them.
/// Requires dependency to GTMAppAuth, see: https://github.com/google/GTMAppAuth
public final class GAppAuth: NSObject {
	
	private static let KeychainPrefix   = Bundle.main.bundleIdentifier!
	private static let KeychainItemName = KeychainPrefix + "GoogleAuthorization"
	
	// Authorization unsuccessful, subscribe if you're interested
	public var errorCallback: ((OIDAuthState, Error) -> Void)?
	
	// Authorization changed, subscribe if you're interested
	public var stateChangeCallback: ((OIDAuthState) -> Void)?
	
	private(set) var authorization: GTMAppAuthFetcherAuthorization?
	
	// Auth scopes
	private var scopes = [OIDScopeOpenID, OIDScopeProfile]
	
	// Used in continueAuthorization(with:callback:) in order to resume the authorization flow after app reentry
	private var currentAuthorizationFlow: OIDExternalUserAgentSession?
	
	private static var singletonInstance: GAppAuth?
	
	public static var shared: GAppAuth {
		if singletonInstance == nil {
			singletonInstance = GAppAuth()
		}
		return singletonInstance!
	}
	
	// No instances allowed
	private override init() {
		super.init()
	}
	
	/// Add another authorization scope to the current set of scopes, i.e. `kGTLAuthScopeDrive` for Google Drive API.
	public func appendAuthorizationRealm(_ scope: String) {
		if !scopes.contains(scope) {
			scopes.append(scope)
		}
	}
	
	/// Starts the authorization flow.
	///
	/// - parameter presentingViewController: The UIViewController that starts the workflow.
	/// - parameter callback: A completion callback to be used for further processing.
	public func authorize(in presentingViewController: UIViewController, clientID: String, redirectUri: String, callback: ((Bool) -> Void)?) throws {
		guard redirectUri != "" else {
			throw GoogleAppAuthError.plistValueEmpty("The value for RedirectUri seems to be wrong, did you forget to set it up?")
		}
		
		guard clientID != "" else {
			throw GoogleAppAuthError.plistValueEmpty("The value for ClientId seems to be wrong, did you forget to set it up?")
		}
		
		let issuer = URL(string: "https://accounts.google.com")!
		let redirectURI = URL(string: redirectUri)!
		
		// Search for endpoints
		OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) {(configuration: OIDServiceConfiguration?, error: Error?) in
			
			if configuration == nil {
				self.setAuthorization(nil)
				return
			}
			
			// Create auth request
			let request = OIDAuthorizationRequest(configuration: configuration!, clientId: clientID, scopes: self.scopes, redirectURL: redirectURI, responseType: OIDResponseTypeCode, additionalParameters: nil)
			
			// Store auth flow to be resumed after app reentry, serialize response
			self.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: presentingViewController) { authState, error in
				var response = false
				if let authState = authState {
					
					let authorization = GTMAppAuthFetcherAuthorization(authState: authState)
					self.setAuthorization(authorization)
					response = true
					
				}
				else {
					self.setAuthorization(nil)
					if let error = error {
						Firappuccino.logger.error("\(error.localizedDescription)")
					}
				}
				
				if let callback = callback {
					callback(response)
				}
			}
		}
	}
	
	/// Continues the authorization flow (to be called from AppDelegate), i.e. in
	///    ```swift
	///     func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
	///    ```
	///
	/// - parameter url: The url that's used to enter the app.
	/// - parameter callback: A completion callback to be used for further processing.
	/// - returns: `true`, if the authorization workflow can be continued with the provided url, otherwise `false`
	public func continueAuthorization(with url: URL, callback: ((Bool) -> Void)?) -> Bool {
		var response = false
		if let authFlow = currentAuthorizationFlow {
			
			if authFlow.resumeExternalUserAgentFlow(with: url) {
				currentAuthorizationFlow = nil
				response = true
			}
			else {
				Firappuccino.logger.error("Error: Couldn't resume authorization flow.")
			}
		}
		
		if let callback = callback {
			callback(response)
		}
		
		return response
	}
	
	/// Determines the current authorization state.
	///
	/// - returns: `true` if there is a valid authorization available, otherwise `false`
	public func isAuthorized() -> Bool {
		return authorization != nil ? authorization!.canAuthorize() : false
	}
	
	/// Loads any existing authorization from the key chain on app start.
	public func retrieveExistingAuthorizationState() {
		let keychainItemName = GAppAuth.KeychainItemName
		if let authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: keychainItemName) {
			setAuthorization(authorization)
		}
	}
	
	/// Resets the authorization state and removes any stored information.
	public func resetAuthorizationState() {
		GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: GAppAuth.KeychainItemName)
		// As keychain and cached authorization token are meant to be in sync, we also have to:
		setAuthorization(nil)
	}
	
	/// Queries the current authorization state
	public func getCurrentAuthorization() -> GTMAppAuthFetcherAuthorization? { return authorization }
	
	/// Stores the authorization.
	internal func setAuthorization(_ authorization: GTMAppAuthFetcherAuthorization?) {
		guard self.authorization == nil || !self.authorization!.isEqual(authorization) else { return }
		
		self.authorization = authorization
		
		if self.authorization != nil {
			self.authorization!.authState.errorDelegate = self
			self.authorization!.authState.stateChangeDelegate = self
		}
		
		serializeAuthorizationState()
	}
	
	/// Saves the authorization result from the workflow.
	internal func serializeAuthorizationState() {
		// No authorization available which can be saved
		guard let authorization = authorization else { return }
		
		let keychainItemName = GAppAuth.KeychainItemName
		if authorization.canAuthorize() {
			GTMAppAuthFetcherAuthorization.save(authorization, toKeychainForName: keychainItemName)
		}
		else {
			// Remove existing authorization state
			GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: keychainItemName)
		}
	}
	//
	
}

extension GAppAuth: OIDAuthStateChangeDelegate {
	
	/// Auth StateDidChange Callback
	/// - Parameter state: AuthState
	public func didChange(_ state: OIDAuthState) {
		guard self.authorization != nil else { return }
		
		let authorization = GTMAppAuthFetcherAuthorization(authState: state)
		self.setAuthorization(authorization)
		
		if let stateChangeCallback = stateChangeCallback {
			stateChangeCallback(state)
		}
	}
	
}

extension GAppAuth: OIDAuthStateErrorDelegate {
	
	// Error callback
	public func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
		guard self.authorization != nil else { return }
		
		currentAuthorizationFlow = nil
		setAuthorization(nil)
		if let errorCallback = errorCallback {
			errorCallback(state, error)
		}
	}
	
}

private enum GoogleAppAuthError: Error {
	case plistValueEmpty(String)
}

#endif

#if os(macOS)
/// Wrapper class that provides convenient AppAuth functionality with Google Services.
/// Set `ClientId`, `RedirectUri` and call respective methods where you need them.
/// Requires dependency to ``GTMAppAuth``, see: https://github.com/google/GTMAppAuth
public final class GoogleAppAuth: NSObject {
	
	private static let KeychainPrefix   = Bundle.main.bundleIdentifier!
	private static let KeychainItemName = KeychainPrefix + "GoogleAuthorization"
	
	/// Authorization unsuccessful, subscribe if you're interested
	public var errorCallback: ((OIDAuthState, Error) -> Void)?
	
	/// Authorization changed, subscribe if you're interested
	public var stateChangeCallback: ((OIDAuthState) -> Void)?
	
	private(set) var authorization: GTMAppAuthFetcherAuthorization?
	
	/// Auth scopes
	private var scopes = [OIDScopeOpenID, OIDScopeProfile]
	
	/// Used in  ```continueAuthorization(with:callback:) in order to resume the authorization flow after app reentry```
	private var currentAuthorizationFlow: OIDExternalUserAgentSession?
	
	private static var singletonInstance: GoogleAppAuth?
	
	public static var shared: GoogleAppAuth {
		if singletonInstance == nil {
			singletonInstance = GoogleAppAuth()
		}
		return singletonInstance!
	}
	
	/// No instances allowed
	private override init() {
		super.init()
	}
	
	/// Add another authorization realm to the current set of scopes, i.e. `kGTLAuthScopeDrive` for Google Drive API.
	public func appendAuthorizationRealm(_ scope: String) {
		if !scopes.contains(scope) {
			scopes.append(scope)
		}
	}
	
	/// Starts the authorization flow.
	///
	/// - parameter callback: A completion callback to be used for further processing.
	public func authorize(clientID: String, clientSecret: String, redirectUri: String, callback: ((Bool) -> Void)?) throws {
		guard redirectUri != "" else {
			throw GoogleAppAuthError.plistValueEmpty("The value for RedirectUri seems to be wrong, did you forget to set it up?")
		}
		
		guard clientID != "" else {
			throw GoogleAppAuthError.plistValueEmpty("The value for ClientId seems to be wrong, did you forget to set it up?")
		}
		
		let issuer = URL(string: "https://accounts.google.com")!
		let redirectURI = URL(string: redirectUri)!
		
		/// Search for endpoints
		OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) {(configuration: OIDServiceConfiguration?, error: Error?) in
			
			if configuration == nil {
				self.setAuthorization(nil)
				return
			}
			
			/// Creates auth request
			let request = OIDAuthorizationRequest(configuration: configuration!, clientId: clientID, clientSecret: clientSecret, scopes: self.scopes, redirectURL: redirectURI, responseType: OIDResponseTypeCode, additionalParameters: nil)
			
			/// Stores auth flow to be resumed after app reentry, serialize response
			self.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: NSWindow(), callback: { authState, error in
				var response = false
				if let authState = authState {
					
					let authorization = GTMAppAuthFetcherAuthorization(authState: authState)
					self.setAuthorization(authorization)
					response = true
					
				}
				else {
					self.setAuthorization(nil)
					if let error = error {
						NSLog("Authorization error: \(error.localizedDescription)")
					}
				}
				
				if let callback = callback {
					callback(response)
				}
			})
			
		}
	}
	
	/// Continues the authorization flow (to be called from AppDelegate), i.e. in
	///     func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
	///
	/// - parameter url: The url that's used to enter the app.
	/// - parameter callback: A completion callback to be used for further processing.
	/// - returns: `true`, if the authorization workflow can be continued with the provided url, otherwise `false`
	public func continueAuthorization(with url: URL, callback: ((Bool) -> Void)?) -> Bool {
		var response = false
		if let authFlow = currentAuthorizationFlow {
			
			if authFlow.resumeExternalUserAgentFlow(with: url) {
				currentAuthorizationFlow = nil
				response = true
			}
			else {
				Firappuccino.logger.error("Error: Could not resume authorization flow.")
			}
		}
		
		if let callback = callback {
			callback(response)
		}
		return response
	}
	
	/// Determines the current authorization state.
	///
	/// - returns: `true` if there is a valid authorization available, otherwise `false`
	public func isAuthorized() -> Bool {
		return authorization != nil ? authorization!.canAuthorize() : false
	}
	
	/// Loads any existing authorization from the key chain on app start.
	public func retrieveExistingAuthorizationState() {
		let keychainItemName = GoogleAppAuth.KeychainItemName
		if let authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: keychainItemName) {
			setAuthorization(authorization)
		}
	}
	
	/// Resets the authorization state and removes any stored information.
	public func resetAuthorizationState() {
		GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: GoogleAppAuth.KeychainItemName)
		// As keychain and cached authorization token are meant to be in sync, we also have to:
		setAuthorization(nil)
	}
	
	/// Queries the current authorization state
	public func getCurrentAuthorization() -> GTMAppAuthFetcherAuthorization? { return authorization }
	
	
	/// Internal: Store the authorization.
	internal func setAuthorization(_ authorization: GTMAppAuthFetcherAuthorization?) {
		guard self.authorization == nil || !self.authorization!.isEqual(authorization) else { return }
		
		self.authorization = authorization
		
		if self.authorization != nil {
			self.authorization!.authState.errorDelegate = self
			self.authorization!.authState.stateChangeDelegate = self
		}
		
		serializeAuthorizationState()
	}
	
	/// Saves the authorization result from the workflow.
	internal func serializeAuthorizationState() {
		// No authorization available which can be saved
		guard let authorization = authorization else { return }
		
		let keychainItemName = GoogleAppAuth.KeychainItemName
		if authorization.canAuthorize() {
			GTMAppAuthFetcherAuthorization.save(authorization, toKeychainForName: keychainItemName)
		}
		else {
			// Remove existing authorization state
			GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: keychainItemName)
		}
	}
	
}

extension GoogleAppAuth: OIDAuthStateChangeDelegate {
	
	public func didChange(_ state: OIDAuthState) {
		guard self.authorization != nil else { return }
		
		let authorization = GTMAppAuthFetcherAuthorization(authState: state)
		self.setAuthorization(authorization)
		
		if let stateChangeCallback = stateChangeCallback {
			stateChangeCallback(state)
		}
	}
	
}

extension GoogleAppAuth: OIDAuthStateErrorDelegate {
	
	/// Error callback
	public func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
		guard self.authorization != nil else { return }
		
		currentAuthorizationFlow = nil
		setAuthorization(nil)
		if let errorCallback = errorCallback {
			errorCallback(state, error)
		}
	}
}

public enum GoogleAppAuthError: Error {
	case plistValueEmpty(String)
}
#endif
