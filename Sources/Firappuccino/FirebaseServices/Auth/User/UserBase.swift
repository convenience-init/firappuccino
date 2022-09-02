import Foundation
import Firebase
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore
import FirebaseFirestoreSwift


/// An extensible base class conforming to `FUser` Protocol
open class UserBase: NSObject, FUser {	
		
	@objc public var id: String
	
	@objc public var createdAt: Date
	
	@objc public var notifications: [FPNMessage] = []
	
	@objc public var disabledMessageCategories: [FPNMessageCategory] = []
	
	@objc public var progress: Int = -1
	
	@objc public var deviceToken: String?
	
	@objc public var appVersion: String
	
	@objc public var lastSignon: Date
	
	@objc public var email: String
	
	@objc public var profileImageURL: String?
	
	@objc public var username: String
	
	@objc public var displayName: String
	
	required public override init() {
		id = "dummy"
		createdAt = Date()
		deviceToken = ""
		appVersion = Bundle.versionString
		lastSignon = Date()
		email = ""
		username = ""
		displayName = ""
		profileImageURL = ""
	}
}

extension UserBase: Identifiable {}
