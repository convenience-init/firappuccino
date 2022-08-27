import Combine

final class ExamplePostService: ObservableObject, Identifiable {
	
	private let postRepository = ExamplePostRepository()
	
	//creates a publisher for post property so you can subscribe to it
	@Published var examplePost: ExamplePost
	
	//store subscriptions so we can cancel them later
	private var cancellables: Set<AnyCancellable> = []
	var id = ""
	
	init(post: ExamplePost) {
		self.examplePost = post
		//Set up a binding for card between the joke’s id and the view model’s id. Then store the object in cancellables so it can be canceled later on
		$examplePost
			.compactMap { $0.id }
			.assign(to: \.id, on: self)
			.store(in: &cancellables)
	}
	
	func update() async throws {
		try await postRepository.update(examplePost)
	}
	
	func remove() async throws {
		try await postRepository.remove(examplePost)
	}
	
//	func add(title: String, message: String) async throws {
//		let newPost = ExamplePost(title: title, message: message)
//		try await postRepository.add(newPost)
//	}
}

