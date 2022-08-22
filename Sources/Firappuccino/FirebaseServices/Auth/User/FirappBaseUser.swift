import Foundation
import Firebase
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore
import FirebaseFirestoreSwift

open class FirappBaseUser: FirappuccinoUser {
	
	public var index: Int?
	
	public var id: String
	
	public var dateCreated: Date
	
	public var notifications: [FPNMessage] = []
	
	public var disabledMessageCategories: [FPNMessageCategory] = []
	
	public var progress: Int = -1
	
	public var deviceToken: String?
	
	public var appVersion: String
	
	public var lastSignon: Date
	
	public var email: String
	
	public var profileImageURL: String?
	
	@objc public var username: String
	
	@objc public var displayName: String
	
	required public init() {
		id = "guest_user"
		dateCreated = Date()
		deviceToken = "-"
		appVersion = Bundle.versionString
		lastSignon = Date()
		email = "guest_user@firappuccino.xyz"
		username = "guest_user"
		displayName = "guest_user"
		profileImageURL = FirappuccinoAuth.defaultProfileImageURL.absoluteString
	}
}
