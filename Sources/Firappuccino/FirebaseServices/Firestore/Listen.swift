import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

extension Firappuccino {
	
	/// A key categorizing Firebase `ListenerRegistration`s.
	public typealias ListenerKey = String
	
	/**
	 A service for listening to data updates on both individual and collections of documents.
	 */
	public struct Listen {
		
		private static var listeners: [ListenerKey: [ListenerRegistration?]] = [:]
		
		///Listen to a collection of documents
		public static func listen<T>(to collectionOfType: T.Type, key: ListenerKey, onUpdate: @escaping ([T]?) -> Void) where T: FDocument {
			let listener = db.collection(colName(of: T.self)).addSnapshotListener { snapshot, error in
				if let error = error {
					Firappuccino.logger.error("No collection named [\(colName(of: T.self))] could be found. \(error.localizedDescription)")
					return onUpdate(nil)
				}
				else if let querySnapshot = snapshot {
					//iterate over all the elements of the snapshot.
					var documents: [T]?
					documents = querySnapshot.documents.compactMap { document in
						//Map every document as an ExamplePost.
						try? document.data(as: T.self)
					}
					onUpdate(documents)
				}
			}
			registerListener(listener, key: key)
		}
		
		public static func listen<T>(to id: DocumentID, ofType type: T.Type, key: ListenerKey, onUpdate: @escaping (T?) -> Void) where T: FDocument {
			let listener = db.collection(colName(of: T.self)).document(id).addSnapshotListener { snapshot, _ in
				guard let snapshot = snapshot, snapshot.exists else {
					Firappuccino.logger.error("A document with ID [\(id)] loaded from the [\(colName(of: T.self))] collection, but no data could be found.")
					return onUpdate(nil)
					
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
