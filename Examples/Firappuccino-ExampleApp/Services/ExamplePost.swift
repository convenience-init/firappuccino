import Foundation
import Firappuccino

class ExamplePost: NSObject, FDocument {
	// Required by `FDocument` protocol
	var id: String = UUID().uuidStringSansDashes
	var createdAt: Date = Date()
	
	// Custom properties
	var userId: String = ""
	var submittingUserDisplayName = ""
	var imageURL: URL = URL(string: "https://source.unsplash.com/random/?guineapig")!
	var updatedAt: Date = Date()
	var title: String = ""
	var message: String = ""
	@objc var likes: Int = 0
	@objc var likedByUserIds: [DocumentID] = []
	
	init(userId: String, submittingUserDisplayName: String, title: String, message: String) {
		self.userId = userId
		self.submittingUserDisplayName = submittingUserDisplayName
		self.title = title
		self.message = message
	}
//	func incrementLikes() async throws {
//		do {
//			try await Firappuccino.Stride.increment(\.likes, by: 1, in: self)
//		}
//		catch let error as NSError {
//			Firappuccino.logger.error("\(error.localizedDescription)")
//		}
//	}
	
	static func == (lhs: ExamplePost, rhs: ExamplePost) -> Bool {
		return lhs.id == rhs.id
	}
}
