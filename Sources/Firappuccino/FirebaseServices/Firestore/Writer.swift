import FirebaseFirestore
import FirebaseFirestoreSwift

public typealias FieldName = String

extension Firappuccino {
	
	/**
	 The `Write` lets `Firappuccino` handle the management of your `FDocument`s in Firestore
	 */
	public struct Writer {
		
		/**
		 Sets a document in Firestore.
		 
		 - parameter document: The document to write in Firestore.
		 */
		
		public static func `write`<T>(_ document: T) async throws where T: FDocument {
			do {
				try await `write`(document, collection: document.typeName, id: document.id)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}

		/**
		 Updates a value for a particular field in Firestore with the current local value.
		 
		 - parameter field: The `FieldName` to update.
		 - parameter document: The document containing the field to update.
		 */
		public static func `updateRemoteField`<T, U>(_ path: ReferenceWritableKeyPath<T, U>, in document: T) async throws where T: FDocument, U: Codable {
			let fieldName: FieldName = path.fieldName
			let localValue = document[keyPath: path]
			let collectionName = String(describing: T.self)
			do {
				try await db.collection(collectionName).document(document.id).updateData([fieldName: localValue])
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Updates a value for a particular field in Firestore.
		 
		 - parameter value: The new value to update.
		 - parameter path: the `KeyPath` to the document's field in Firestore.
		 - parameter document: The document with the field to update.
		 */
		public static func `updateField`<T, U>(_ path: ReferenceWritableKeyPath<T, U>, in document: T, with value: U) async throws where T: FDocument, U: Codable {
			let collectionName = String(describing: T.self)
			let fieldName: FieldName = path.fieldName
			
			do {
				try await db.collection(collectionName).document(document.id).updateData([fieldName: value])
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Writes the child object to Firestore, then links it to the specified field of `DocumentID`s in the parent document.
		 
		 - parameter document: The document to store in Firestore.
		 - parameter child: The child document (only used to `fetch` an ID).
		 - parameter path: The path of the parent document's field containing the list of `DocumentID`s.
		 - parameter parent: The parent document containing the list of `DocumentID`s.
		 */
		public static func writeAndRelate<T, U>(_ document: T, using path: ReferenceWritableKeyPath<U, [DocumentID]>, in parent: U) async throws where T: FDocument, U: FDocument {
			
			do {
				try await `write`(document)
				try await Relator.`relate`(document, using: path, in: parent)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Sets a (default) document in Firestore only if the document does not exist.
		 
		 This method is used to create new documents in Firestore without being destructive. For instance, if user objects have other document types unique to them, you may want to create these new documents under the condition that they don't already exist to prevent user data loss.
		 
		 - parameter document: The document to write in Firestore.
		 - parameter id: The ID of the document to check in Firestore. If set to `nil`, the ID of the document being write will be used to check.
		 */
		
		public static func safeCreate<T>(_ document: T, checking id: DocumentID? = nil) async throws where T: FDocument {
			
			var checkID = document.id
			if let id = id {
				checkID = id
			}
			
			do {
				let _document = try await db.collection(String(describing: T.self)).document(checkID).getDocument().data(as: T.self)
				try await `write`(_document)
				
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/// Sets a passed `FDocument` in `Firestore` remote db
		/// - Parameters:
		///   - model: An object that adopts `FModel`.
		///   - collection: The `String` name of the collection to `write` the document
		///   - id: The `id` of the document to write
		private static func `write`<T>(_ model: T, collection: CollectionName = "", id: String) async throws where T: FModel {
			var _collection = collection
			if collection.isEmpty {
				_collection = String(describing: T.self)
			}
			do {
				let document = db.collection(_collection).document(id)
				try document.setData(from: model)
				
				Firappuccino.logger.info("FDocument ID: \(id) successfully written to [\(collection)] collection.")
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
	}
	//
}
