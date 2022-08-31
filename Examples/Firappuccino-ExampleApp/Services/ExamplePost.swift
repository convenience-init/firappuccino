import Foundation
import Firappuccino

class ExamplePost: NSObject, FDocument {
	// Required by `FDocument` protocol
	var id: String = UUID().uuidStringSansDashes
	var createdAt: Date = Date()
	
	// Custom properties
	@objc var userId: String = ""
	@objc var submittingUserDisplayName = ""
	@objc var imageURL: URL = URL(string: "https://source.unsplash.com/random/?guineapig")!
	@objc var updatedAt: Date = Date()
	@objc var title: String = ""
	@objc var message: String = ""
	@objc var likes: Int = 0
	@objc var likedByUserIds: [DocumentID] = []
	
	init(userId: String, submittingUserDisplayName: String, title: String, message: String) {
		self.userId = userId
		self.submittingUserDisplayName = submittingUserDisplayName
		self.title = title
		self.message = message
	}
	
	static func == (lhs: ExamplePost, rhs: ExamplePost) -> Bool {
		return lhs.id == rhs.id
	}
}
