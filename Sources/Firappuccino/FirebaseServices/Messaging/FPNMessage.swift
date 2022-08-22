
/** A `typealias` representing the `String` name of the message category.
 
 You can implement an enum of custom categories in your app if you like:
 ````
 enum MessageCategory: FPNMessageCategory {
 case _none
 case _all
 }
 ````
 */
public typealias FPNMessageCategory = String


/// A Notification sent from one `FirappuccinoUser` to another which can be programatically triggered by any event from within your app.
///
/// "*FirappuccinoUser X* liked your content *XXX*!"
///
/// "*FirappuccinoUser X* reported your post *XXX*!"
///
/// "*FirappuccinoUser X* responded to your question *XXX*!"
///
/// - Remark: If you want to send a message with just a title and a body to a user, call
///	````
///	FPNMessaging.sendNotificationTo<T>(to:title:body:data:)
///	````
public class FPNMessage: FirappuccinoDocumentModel {
	
	/// The date of the notification.
	public var date: Date = Date()
	
	/** The notification's category.
	 This value can be used to limit user notifications by appending it to the array
	 
	 Example:
	 ```
	 MyFirappuccinoUser.disabledNotificationCategories.append(category)
	 ```
	 */
	public var category: FPNMessageCategory
	
	/// The user that this notification came from.
	public var user: DocumentID?
	
	
	/// The title of the notification.
	/// - Note: if none is specified, an empty `String` is passed and ``FirebaseMessaging`` defaults (your project/app name) will be used.
	public var title: String
	
	/** The notification message's body text.
	 - Important: Do not include a placeholder for the user. The receiver's `displayName` will **automatically** be prepended to the message `text`.
	 - Remark: If you set `messageBody` to `"is stalking you!"`, the end user will receive the notification "*Firappuccino X* is stalking you!".
	 */
	public var messageBody: String
	
	/// The body of the push notification.
	public var pushBody: String
	
	/// The attached image URL `String` for the notification. If not passed a value, ``FirebaseMessaging`` default will be used.
	public var image: String?
	
	/// Whether the notification has been read
	public var read: Bool = false
	
	public init<T>(_ title: String = "", messageBody: String, sender sendingUser: T, category: FPNMessageCategory, imageFromURL: String? = nil, additionalInfo: String? = nil) where T: FirappuccinoUser {
		self.title = title
		self.user = sendingUser.id
		self.messageBody = messageBody
		self.category = category
		self.pushBody = "\(sendingUser.displayName) \(self.messageBody)"
		
		if let imageURL = imageFromURL {
			self.image = imageURL
		}
		
		if let additionalInfo = additionalInfo {
			self.pushBody += ": \(additionalInfo)"
			self.messageBody += ": \(additionalInfo)"
		}
	}
}

extension FPNMessage: Equatable {
	public static func == (lhs: FPNMessage, rhs: FPNMessage) -> Bool {
		return lhs.messageBody == rhs.messageBody && (lhs.date.distance(to: rhs.date)) < TimeInterval(5 * 60)
	}
}
