import Foundation
import Firebase
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore
import FirebaseFirestoreSwift

public final class KeyPathable: FieldNameReferenceable {
	public static var fieldNames: [PartialKeyPath<KeyPathable> : String] {
		[:]
	}
}

open class FUserBase: NSObject, FUser {
	
	public var index: Int?
	
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
	
	public var displayName: String
	
	required public override init() {
		id = "dummy"
		index = -1
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

extension FUserBase: Identifiable {}
