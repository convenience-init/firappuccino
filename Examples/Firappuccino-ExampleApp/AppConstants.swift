import UIKit

struct AppConstants {
	
	struct userDefaults {
		static let didWalkThroughKey = "didWalkThrough"
	}
	static let clientID = "10095415638-e0o8v95buts4qagu6qqk9t2o5be0hqpn"
	static let googleAppID = "1:10095415638:ios:4aa5cc494103b3cc6986f7"
	static let gcmSenderID =  "10095415638"
	static let gcmMessageIDKey = "gcm.message_id"
	static let apiKey = "AIzaSyBhoYnRt_pIQbEavlhtDWY3N171pl-to30"
	static let privateKeyPath = URL(fileReferenceLiteralResourceName: "privateKey").relativePath
	static let publicKeyPath = URL(fileReferenceLiteralResourceName: "publicKey").relativePath
	static let projectID = "hilarist-authentication"
	static let legacyMessagingAPIKey = "AAAAAlm70VY:APA91bHReDsmGJIIO2eP1s7ss10mjOzhDGUb0fVIEENPW3s0twlrhhJ64mGSgwnqvLkHGk7BkJkLa9B1_IT6nsUBO58VjvbYTMQtvgrKOHvylFOqbigHOZjbRt2LNbUfoS1zvE1Zv6t4"
	static let messagingCustomImagePath = URL(fileReferenceLiteralResourceName: "pushImage").absoluteString
	static let iss = "firebase-adminsdk-3gswh@hilarist-authentication.iam.gserviceaccount.com"
	static let placeholderProfileImageUrl = URL(string: "https://firebasestorage.googleapis.com/v0/b/hilarist-authentication.appspot.com/o/FCMImages%2FHilaristPreviewProfileImage.png?alt=media&token=0d1a5276-4cea-4562-a0d2-c14c5cc6571b")!
	
	static let placeholderPostImageUrl = URL(string: "https://img-fotki.yandex.ru/get/9262/252028825.1d/0_d8996_f30300ab_orig.jpg")
	
}
