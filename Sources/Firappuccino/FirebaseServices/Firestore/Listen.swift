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
		
		public static func listen<T>(to id: DocumentID, ofType type: T.Type, key: ListenerKey) async throws -> T? where T: FirappuccinoDocument {
			return try await withCheckedThrowingContinuation { continuation in
				listen(to: id, ofType: type, key: key) { onUpdate in
					let listener = db.collection(colName(of: T.self)).document(id).addSnapshotListener { snapshot, _ in
						
						guard let snapshot = snapshot, snapshot.exists else {
							Firappuccino.logger.error("A document with ID [\(id)] loaded from the [\(colName(of: T.self))] collection, but no data could be found.")
							continuation.resume(returning: nil)
							return
						}
						guard let document = try? snapshot.data(as: T.self) else {
							Firappuccino.logger.error("A document with ID [\(id)] loaded from the [\(colName(of: T.self))] collection, but couldn't be decoded.")
							return
						}
						continuation.resume(returning: document)
					}
					registerListener(listener, key: key)
				}
			}
		}
		
		public static func listen<T>(to id: DocumentID, ofType type: T.Type, key: ListenerKey, onUpdate: @escaping (T?) -> Void) where T: FirappuccinoDocument {
			let listener = db.collection(colName(of: T.self)).document(id).addSnapshotListener { snapshot, _ in
				guard let snapshot = snapshot, snapshot.exists else {
					Firappuccino.logger.error("A document with ID [\(id)] loaded from the [\(colName(of: T.self))] collection, but no data could be found.")
					onUpdate(nil)
					return
				}
				var document: T?
				try? document = snapshot.data(as: T.self)
				guard let document = document else {
					Firappuccino.logger.error("A document with ID [\(id)] loaded from the [\(colName(of: T.self))] collection, but couldn't be decoded.")
					return
				}
				onUpdate(document)
			}
			registerListener(listener, key: key)
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
