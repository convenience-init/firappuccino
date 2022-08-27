import Foundation
import Firebase
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore
import FirebaseFirestoreSwift

open class FUserBase: NSObject, FUser {	
	
	public var index: Int?
	
	public var id: String
	
	public var createdAt: Date
	
	public var notifications: [FPNMessage] = []
	
	public var disabledMessageCategories: [FPNMessageCategory] = []
	
	public var progress: Int = -1
	
	public var deviceToken: String?
	
	public var appVersion: String
	
	public var lastSignon: Date
	
	public var email: String
	
	public var profileImageURL: String?
	
	public var username: String
	
	public var displayName: String
	
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
