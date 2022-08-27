import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

extension Firappuccino {
	
	/// A key categorizing Firebase `ListenerRegistration`s.
	public typealias ListenerKey = String
	
	/**
	 A service for listening to data updates within documents.
	 */
	public struct Listen {
		
		private static var listeners: [ListenerKey: [ListenerRegistration?]] = [:]
		
		@available(*, renamed: "listen(ofType:key:)")
		public static func `listen`<T>(ofType type: T.Type, key: ListenerKey, onUpdate: @escaping ([T]?) -> Void) where T: FDocument {
			Task {
				let result: [T]? = await `listen`(ofType: type, key: key)
				onUpdate(result)
			}
		}
		
		public static func `listen`<T>(ofType type: T.Type, key: ListenerKey) async -> [T]? where T: FDocument {
			return await withCheckedContinuation { continuation in
				let listener = db.collection(colName(of: T.self)).addSnapshotListener { querySnapshot, error in
					if let error = error {
						Firappuccino.logger.error("Error adding listener to [\(colName(of: T.self))] collection: \(error.localizedDescription)")
						continuation.resume(returning: nil)
						return
					}
					//iterate over all the elements of the snapshot. If querySnapshot is nil, set an empty array instead.
					var documents: [T]?
					documents = querySnapshot?.documents.compactMap { document in
						//Map every document as an ExamplePost using data(as:decoder:).
						try? document.data(as: T.self)
					} ?? []
					continuation.resume(returning: documents)
				}
				registerListener(listener, key: key)
			}
		}
		
		@available(*, renamed: "listen(to:ofType:key:)")
		public static func `listen`<T>(to id: DocumentID, ofType type: T.Type, key: ListenerKey, onUpdate: @escaping (T?) -> Void) where T: FDocument {
			Task {
				let result: T? = await listen(to: id, ofType: type, key: key)
				onUpdate(result)
			}
		}
		
		public static func `listen`<T>(to id: DocumentID, ofType type: T.Type, key: ListenerKey) async -> T? where T: FDocument {
			return await withCheckedContinuation { continuation in
				let listener = db.collection(colName(of: T.self)).document(id).addSnapshotListener { snapshot, _ in
					guard let snapshot = snapshot else {
						Firappuccino.logger.error("A document with ID [\(id)] loaded from the [\(colName(of: T.self))] collection, but no data could be found.")
						continuation.resume(returning: nil)
						return
					}
					var document: T?
					try? document = snapshot.data(as: T.self)
					guard let document = document else {
						Firappuccino.logger.error("A document with ID [\(id)] loaded from the [\(colName(of: T.self))] collection, but couldn't be decoded.")
						return
					}
					continuation.resume(returning: document)
				}
				registerListener(listener, key: key)
			}
		}
		
		public static func stop(_ key: ListenerKey) {
			guard let keyListeners: [ListenerRegistration?] = listeners[key] else { return }
			for listener in keyListeners {
				listener?.remove()
			}
		}
		
		internal static func registerListener(_ listener: ListenerRegistration, key: ListenerKey) {
			if listeners[key] != nil {
				listeners[key]?.append(listener)
			}
			else {
				listeners[key] = [listener]
			}
		}
	}
}
