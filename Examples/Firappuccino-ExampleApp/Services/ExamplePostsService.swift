import Foundation
import Combine
import Firappuccino
import FirebaseFirestore
import FirebaseFirestoreSwift

class ExamplePostsService: ObservableObject {
	@Published var postRepository = ExamplePostRepository()
	@Published var postServices: [ExamplePostService] = []
	
	private var cancellables: Set<AnyCancellable> = []
	
	init() {
		// Add a listener to and map every element of the `examplePosts` array in the `postRepository` into an `ExamplePostService`, creatng an array of `ExamplePostService`, one for each post.

		postRepository.$examplePosts.map { posts in
			posts.map(ExamplePostService.init)
		}
		.assign(to: \.postServices, on: self)
		.store(in: &cancellables)
	}
	
	
	/// Writes a new post to `Firestore`
	/// - Parameters:
	///   - post: the `ExamplePost` to upload
	///   - image: optional `UIImage` to attach to the post and store in `FirebaseStorage`
	func addPost(_ post: ExamplePost, image: UIImage? = nil) async throws {
		try await postRepository.add(post, with: image)
	}
	
	/// Removes a post
	func removePost(_ post: ExamplePost) async throws {
		try await postRepository.remove(post)
	}
	
	/// Updates a post
	func updatePost(_ post: ExamplePost) async throws {
		try await postRepository.update(post)
	}
	
	/// Like a post
	func likePost(_ post: ExamplePost) async throws {
		try await postRepository.like(post)
	}
}
