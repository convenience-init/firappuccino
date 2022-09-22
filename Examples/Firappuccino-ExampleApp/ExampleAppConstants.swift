import UIKit
import Firappuccino
import Logging

class ExampleAppConstants {
	
	var didFinishWalkThroughKey: String?
	var clientID: String?
	var googleAppID: String?
	var gcmSenderID: String?
	var apiKey: String?
	var projectID: String?
	var gcmMessageIDKey: String?
	var iss: String? // for JWT generation if using v1 Messaging API
	var legacyMessagingServerKey: String? // "Server Key" for legacy Messaging API
	
	let messagingCustomImagePath = Bundle.main.url(forResource: "pushImage", withExtension: ".png")?.absoluteString
	
	let privateKeyPath = Bundle.main.url(forResource: "messageSendPrivate", withExtension: "._key")?.relativePath
	
	let publicKeyPath = Bundle.main.url(forResource: "messageSendPublic", withExtension: "._key")?.relativePath

	let placeholderProfileImageUrl = URL(string: "YOUR_REMOTE_DEFAULT_PROFILE_IMAGE_URL_STRING")!
	
	let placeholderPostImageUrl = URL(string: "YOUR_REMOTE_PLACEHOLDER_IMAGE_URL_STRING")!
	
	private init() {
		try? self.readGooglePlistValues()
	}
	
	static var shared = ExampleAppConstants()
	
	private func readGooglePlistValues() throws {
		
		var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list
		
		var plistData: [String:AnyObject] = [:]
		
		guard let plistPath: String = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
			fatalError("NO PLIST PRESENT! YOU MUST ADD THE GOOGLESERVICE PLIST TO THE ROOT OF YOUR APP BEFORE BUILDING!")
		}
		
		let plistXML = FileManager.default.contents(atPath: plistPath)!
		
		do {
			plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &format) as! [String: AnyObject]
			guard plistData["PROJECT_ID"] as! String != "testapp-00000" else {
				fatalError("DUMMY PLIST IS STILL PRESENT. YOU MUST ADD THE GOOGLESERVICE PLIST TO THE ROOT OF YOUR APP BEFORE BUILDING!")
			}
			
			self.clientID = plistData["CLIENT_ID"] as? String
			self.googleAppID = plistData["GOOGLE_APP_ID"] as? String
			self.gcmMessageIDKey = plistData["GCM_MESSAGE_ID_KEY"] as? String
			self.gcmSenderID = plistData["GCM_SENDER_ID"] as? String
			self.apiKey = plistData["API_KEY"] as? String
			self.projectID = plistData["PROJECT_ID"] as? String
			self.iss = plistData["ISS"] as? String
			self.apiKey = plistData["LEGACY_API_SERVER_KEY"] as? String
			self.didFinishWalkThroughKey = plistData["DID_WALKTHROUGH_KEY"] as? String
	
		}
		catch let error as NSError {
			Firappuccino.logger.critical("Error reading plist: \(error), format: \(format)")
			throw error
		}
	}
}

