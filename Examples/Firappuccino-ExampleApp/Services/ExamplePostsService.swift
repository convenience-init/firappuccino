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
		//Listen to and map every element of the `examplePosts` array in the `postRepository` into an `ExamplePostService`, creatng an array of `ExamplePostService`, one for each item.

		postRepository.$examplePosts.map { posts in
			posts.map(ExamplePostService.init)
		}
		.assign(to: \.postServices, on: self)
		.store(in: &cancellables)
		///
//		repository.$examplePosts.assign(to: \.examplePosts, on: self)
//			.store(in: &cancellables)
//
//		ExampleAuthService.currentSession.$currentUser
//			.receive(on: DispatchQueue.main)
//			.sink { [weak self] _ in
//			self?.repository.get()
//		}
//		.store(in: &cancellables)
	}
	
	func addPost(_ post: ExamplePost, image: UIImage? = nil) async throws {
		try await postRepository.add(post, with: image)
	}
	
	func removePost(_ post: ExamplePost) async throws {
		try await postRepository.remove(post)
	}
	
	func updatePost(_ post: ExamplePost) async throws {
		try await postRepository.update(post)
	}
}
