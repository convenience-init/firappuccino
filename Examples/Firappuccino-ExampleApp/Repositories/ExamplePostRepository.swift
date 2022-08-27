import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseFunctions
import Combine
import Firappuccino

final class ExamplePostRepository: ObservableObject {
	
	@Published var examplePosts: [ExamplePost] = []
	@Published var error: NSError? = nil
	
	var cancellables: Set<AnyCancellable> = []
	private lazy var functions = Functions.functions(region: "us-central1")
	private var path = "ExamplePost"
	private var userId = ""
	private let authService = ExampleAuthService.currentSession
	private let store = Firappuccino.db

	init() {
		//Bind hilaristUser‘s id from UserSession to the repository’s userId. It also stores the object in cancellables so it can be canceled later.
		authService.$currentUser
			.compactMap { user in
				user.id
			}
			.assign(to: \.userId, on: self)
			.store(in: &cancellables)
		//This code observes the changes in user, uses receive(on:options:) to set the thread where the code will execute and then attaches a subscriber using sink(receiveValue:). This guarantees that when you get a user from HilaristsAuthenticationManager, the code in the closure executes in the main thread.
		authService.$currentUser
			.receive(on: DispatchQueue.main)
			.sink { [weak self] _ in
				self?.get()
			}
			.store(in: &cancellables)
	}
	
	func get() {
		guard !authService.currentUser.isDummy else { return }
		store.collection(path)
			.whereField("message", isEqualTo: "Test message")
			.order(by: "createdAt", descending: true)
			.addSnapshotListener { querySnapshot, error in
				if let error = error {
					Firappuccino.logger.error("\(error.localizedDescription)")
				}
				self.examplePosts = querySnapshot?.documents.compactMap { document in
					try? document.data(as: ExamplePost.self)
				} ?? []
			}
	}
	func attachImage(to post: ExamplePost, using data: Data, andPath: String, progress: @escaping (Double) -> Void = { _ in }) async throws -> URL? {
		
		do {
			return try await FirappuccinoStorageResource.attachImageResource(to: post, using: data, andPath: andPath, progress: progress)
		}
		catch let error {
			self.error = NSError(domain: "app.hilarists.HilaristsApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
			}
		}
	
//	func add(_ post: ExamplePost) async throws {
//		try await update(post)
//	}
	
	func add(_ post: ExamplePost, with image: UIImage? = nil) async throws {
		var post = post
		if let image = image {
			do {
				if let imageData = image.pngData(), let url = try await attachImage(to: post, using: imageData, andPath: "Post Images") {
					post.userId = userId
					post.imageURL = url
					try await update(post)
				}
			}
			catch let error as NSError {
				self.error = NSError(domain: "app.hilarists.HilaristsApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
				Firappuccino.logger.error("\(String(describing: self.error))")
				throw error
			}
		}
		else {
			do {
				try await update(post)
			}
			catch let error as NSError {
				self.error = NSError(domain: "app.hilarists.HilaristsApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
				Firappuccino.logger.error("\(String(describing: self.error))")
				throw error
			}
		}
	}
	
	func update(_ post: ExamplePost) async throws {
		let updatedPost = post
		//FIXME: - need to be able to update image here too
		do {
			try await updatedPost.write()
		}
		catch let error as NSError {
			self.error = NSError(domain: "app.hilarists.HilaristsApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(String(describing: self.error))")
			throw error
		}
	}
	
	func remove(_ post: ExamplePost) async throws {
		//TODO: Cascade delete images
		do {
			try await Firappuccino.Trash.remove(post)
		}
		catch let error as NSError {
			self.error = NSError(domain: "app.hilarists.HilaristsApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(String(describing: self.error))")
			throw error
		}
	}
}
