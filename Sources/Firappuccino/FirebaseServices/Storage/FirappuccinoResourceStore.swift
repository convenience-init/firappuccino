import Foundation
import Firebase
import FirebaseStorage
import FirebaseStorageSwift

/**
 `FirappuccinoResourceStore` allows `Firappuccino` to manage all of the various functions related to Firebase Resource Storage.
 
 To use `FirappuccinoResourceStore`, check out the following methods:
 
 - `put(_:to:progress:)` to store resource data in Firebase Storage.
 - `delete(_:)` to remove resoure data from Firebase Storage.
 */
public struct FirappuccinoResourceStore {
	
	private static let storage = Storage.storage()
	
	private static let storageRef = storage.reference()
	
	/// The active storage upload task.
	public private(set) static var task: StorageUploadTask?
	
	/// Stores a resource in Firebase Storage.
	/// This is a safe method. Existing resources with a matching ID will be removed from Firebase Storage before the resource is added.
	/// - Parameters:
	///   - data: The data to store.
	///   - resource: A `FirappuccinoStorageResource` object with information about the resource being stored.
	///   - progress: A closure for handling progress updates.
	/// - Returns: A valid `URL` to the resource or `nil`
	/// - Throws: An `Error`
	@MainActor public static func put(_ data: Data, to resource: FirappuccinoStorageResource, progress: @escaping (Double) -> Void = { _ in }) async -> URL? {
		await delete(resource)
		return await unsafePut(data, to: resource, progress: progress)
	}
	
	/**
	 Removes a resource from Firebase Storage.
	 
	 - parameter resource: Information about the location of the resource in Firebase Storage.
	 - parameter completion: The completion handler.
	 */
	@discardableResult
	@MainActor public static func delete(_ resource: FirappuccinoStorageResource) async -> Bool {
		let ref = storageRef.child(resource.path)
		return await withCheckedContinuation { continuation in
			ref.delete(completion: { err in
				if err != nil {
					print("[!] No resource was deleted because no resource exists.")
					continuation.resume(returning: false)
				}
				else {
					continuation.resume(returning: true)
				}
			})
		}
	}
	
	/**
	 Pauses an upload task.
	 */
	@MainActor public static func pause() {
		task?.pause()
	}
	
	/**
	 Resumes an upload task.
	 */
	@MainActor public static func resume() {
		task?.resume()
	}
	
	/**
	 Cancels an upload task.
	 */
	@MainActor public static func cancel() {
		task?.cancel()
	}
	
	@available(*, renamed: "unsafePut(_:to:progress:)")
	@MainActor private static func unsafePut(_ data: Data, to resource: FirappuccinoStorageResource, progress: @escaping (Double) -> Void, completion: @escaping (URL?) -> Void = { _ in }) {
		Task {
			let result = await unsafePut(data, to: resource, progress: progress)
			completion(result)
		}
	}
	
	@discardableResult
	@MainActor private static func unsafePut(_ data: Data, to resource: FirappuccinoStorageResource, progress: @escaping (Double) -> Void) async -> URL? {
		let ref = storageRef.child(resource.path)
		let metadata = StorageMetadata()
		metadata.contentType = resource.kind.contentType()
		return await withCheckedContinuation { continuation in
			task = ref.putData(data, metadata: metadata) { (_, _) in
				task?.removeAllObservers()
				task = nil
				ref.downloadURL { (url, error) in
					if let error = error {
						Firappuccino.logger.error("\(error.localizedDescription)")
					}
					if let url = url {
						resource.url = url
						continuation.resume(returning: url)
					}
				}
			}
			_ = task?.observe(.progress, handler: { snapshot in
				progress(snapshot.progress?.fractionCompleted ?? 0.0)
			})
		}
	}
}
