import Combine
import Foundation
import Firappuccino
import FirebaseFunctions
import FirebaseFirestore
import FirebaseFirestoreSwift

final class ExamplePostRepository: ObservableObject {
	
	@Published var examplePosts: [ExamplePost] = []
	@Published var error: NSError? = nil
	
	private lazy var functions = Functions.functions(region: "us-central1")
	
	private var cancellables: Set<AnyCancellable> = []
	
	private var userId = ""
	private let authService = ExampleAuthService.currentSession
	private lazy var store = { return Firappuccino.db }()
	
	init() {
		// assigns `user.id` to `repository.userId` binding the user and repository
		authService.$currentUser
			.compactMap { user in
				user.id
			}
			.assign(to: \.userId, on: self)
			.store(in: &cancellables)
		
		// observes the changes in user on the main thread and then attaches a subscriber using sink(receiveValue:)
		authService.$currentUser
			.receive(on: DispatchQueue.main)
			.sink { [weak self] _ in
				self?.get()
			}
			.store(in: &cancellables)
	}
	
	
	/// Sets up a snapshot listener on the `ExamplePost` collection and assigns the results to the repository's @Published `examplePosts` array.
	func get() {
		guard !authService.currentUser.isDummy else { return }
		
		Firappuccino.Listener.`listen`(to: ExamplePost.self, key: "EXAMPLE_POSTS_UPDATED") { documents in
			guard let documents = documents else {
				return
			}
			self.examplePosts = documents
		}
	}
	
	///Attaches an image to an `ExamplePost` and uploads it to `FirebaseStorage`
	func attachImage(to post: ExamplePost, using data: Data, andPath: String, progress: @escaping (Double) -> Void = { _ in }) async throws -> URL? {
		
		do {
			return try await FirappuccinoStorageResource.attachImageResource(to: post, using: data, andPath: andPath, progress: progress)
		}
		catch let error {
			self.error = NSError(domain: "xyz.firappuccino.Firappuccino-ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	func add(_ post: ExamplePost, with image: UIImage? = nil) async throws {
		if let image = image {
			do {
				if let imageData = image.pngData(), let url = try await attachImage(to: post, using: imageData, andPath: "Post Images") {
					post.userId = userId
					post.submittingUserDisplayName = authService.currentUser.displayName
					post.imageURL = url
					try await update(post)
				}
			}
			catch let error as NSError {
				self.error = NSError(domain: "xyz.firappuccino.Firappuccino-ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
				Firappuccino.logger.error("\(String(describing: self.error))")
				throw error
			}
		}
		else {
			do {
				post.userId = userId
				post.submittingUserDisplayName = authService.currentUser.displayName
				try await update(post)
			}
			catch let error as NSError {
				self.error = NSError(domain: "xyz.firappuccino.Firappuccino-ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
				Firappuccino.logger.error("\(String(describing: self.error))")
				throw error
			}
		}
	}
	
	func update(_ post: ExamplePost) async throws {
		let updatedPost = post
		// TODO: - update post image
		do {
			try await updatedPost.write()
		}
		catch let error as NSError {
			self.error = NSError(domain: "xyz.firappuccino.Firappuccino-ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(String(describing: self.error))")
			throw error
		}
	}
	
	func remove(_ post: ExamplePost) async throws {
		// TODO: Cascade delete images
		do {
			try await Firappuccino.Destroyer.`destroy`(post)
		}
		catch let error as NSError {
			self.error = NSError(domain: "xyz.firappuccino.Firappuccino-ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(String(describing: self.error))")
			throw error
		}
	}
	
	func like(_ post: ExamplePost) async throws {
		do {
			try await likeUserPostAction(post)
		}
		catch let error as NSError {
			self.error = NSError(domain: "xyz.firappuccino.Firappuccino-ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(String(describing: self.error))")
			throw error
		}
	}
}

extension ExamplePostRepository {
	
	private func likeUserPostAction(_ post: ExamplePost) async throws {
		let postToLike = post
		
		do {
			
			try await linkUserId(to: postToLike, fieldName: "likedByUserIds")
			
			try await updateValuesOnLikePostAction(postToLike)
			
			let recipient = try await fetchUser(id: postToLike.userId)
			
			try await sendFPNMessage(to: recipient, messageBody: "liked your Post: '\(postToLike.title)'!!", attachmentImageURL: ExampleAppConstants.shared.placeholderPostImageUrl.absoluteURL, additionalInfo: " Sending and receiving Cloud Messages is a breeze with the Firappuccino framework...")
		}
		catch let error as NSError {
			self.error = NSError(domain: "xyz.firappuccino.Firappuccino-ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(String(describing: self.error))")
			throw error
		}
		
	}
	
	/// `relate` userId to ExamplePost's `likedByUserIds` field
	private func linkUserId(to post: ExamplePost, fieldName: String) async throws {
		do {
			try await Firappuccino.Relator.`relate`(authService.currentUser, using: \.likedByUserIds, in: post)
		}
		catch let error as NSError {
			self.error = NSError(domain: "xyz.firappuccino.Firappuccino-ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(String(describing: self.error))")
			throw error
		}
	}
	
	///Updates Values
	private func updateValuesOnLikePostAction(_ post: ExamplePost) async throws {
		//		var post = post
		let originalPoster = try await fetchUser(id: post.userId)
		
		let likingUser = authService.currentUser
		
		// Updates for `ExamplePost`
		try await post.incrementField(\.likes, by: 1)
		
		//		or...
		//		try await Firappuccino.Updater.incrementField(\ExamplePost.likes, by: 1, in: post)
		
		// Updates for `OP`
		try await originalPoster.incrementField(\.totalLikesReceived, by: 1)
		
		//		or..
		//		try await Firappuccino.Updater.incrementField(\ExampleFUser.totalLikesReceived, by: 1, in: originalPoster)
		
		// writes updates
		do {
			try await likingUser.write()
			try await post.write()
			try await originalPoster.write()
		}
		catch let error as NSError {
			self.error = NSError(domain: "xyz.firappuccino.Firappuccino-ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(String(describing: self.error))")
			throw error
		}
	}
}

extension ExamplePostRepository {
	
	private func fetchUser(id: String) async throws -> ExampleFUser {
		var user = ExampleFUser()
		let ref = store.collection(Firappuccino.colName(of: ExampleFUser.self)).document(id)
		do {
			user = try await ref.getDocument(as: ExampleFUser.self)
		}
		catch let error as NSError {
			self.error = NSError(domain: "xyz.firappuccino.Firappuccino-ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(String(describing: self.error))")
			throw error
		}
		return user
	}
	
	
	//attachmentImageURL:  URL(string: "https://firebasestorage.googleapis.com/v0/b/hilarist-authentication.appspot.com/o/FCMImages%2FHilaristPreviewProfileImage.png?alt=media&token=0d1a5276-4cea-4562-a0d2-c14c5cc6571b")!
	
	// Messaging
	private func sendFPNMessage(to recipient: ExampleFUser, messageBody: String, attachmentImageURL: URL?, additionalInfo: String?) async throws {
		// TODO: `Categories` param
		do {
			try await FPNManager.sendUserMessage(from: authService.currentUser, to: recipient, messageBody: messageBody, attachmentImageURL: attachmentImageURL, additionalInfo: additionalInfo)
			
		}
		catch let error as NSError {
			self.error = NSError(domain: "xyz.firappuccino.Firappuccino-ExampleApp", code: 666, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
			Firappuccino.logger.error("\(String(describing: self.error))")
			throw error
		}
	}
}
