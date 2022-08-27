import Foundation
import Firappuccino

struct ExamplePost: FDocument {
	// Required by `FDocument` protocol
	var id: String = UUID().uuidStringSansDashes
	var createdAt: Date = Date()
	
	// Custom properties
	var userId = ""
	var imageURL: URL = AppConstants.placeholderProfileImageUrl
	var updatedAt: Date = Date()
	var title: String = ""
	var message: String = ""
}
