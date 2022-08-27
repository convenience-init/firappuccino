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
		//Listen to cards and maps every Joke element of each `jokes` array in the repository into a JokeItemViewModel. This will create an array of JokeItemViewModels for each joke array.
		
		// Posts
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
	
	func updateJoke(_ post: ExamplePost) async throws {
		try await postRepository.update(post)
	}
//	func add(title: String, message: String, image: UIImage? = nil) async throws {
//		//TODO: refactor for image attachment
//		let newPost = ExamplePost(title: title, message: message)
//		try await postRepository.add(newPost)
//	}
}
