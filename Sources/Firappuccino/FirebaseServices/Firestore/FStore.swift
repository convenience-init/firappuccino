import FirebaseFirestore
import FirebaseFirestoreSwift

public typealias FieldName = String

extension Firappuccino {
	
	/**
	 The `FStore` lets `Firappuccino` handle the management of your `FDocument`s in Firestore
	 */
	public struct FStore {
		
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
		 Sets a `Individuatable` in Firestore.
		 
		 - parameter uniqueDocument: The `Individuatable` to write in Firestore.
		 - parameter completion: The completion handler.
		 */
		
		public static func `write`<T>(_ uniqueDocument: T) async throws where T: Individuatable {
			do {
				try await `write`(uniqueDocument, collection: "Individuatable", id: uniqueDocument.id)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Updates a value remotely for a particular field in Firestore with the current local value.
		 
		 - parameter path: The `KeyPath` to the document's field to update.
		 - parameter document: The document with the updated field.
		 */
//		public static func `write`<T, U>(field: FieldName = "", using path: KeyPath<T, U>, in document: T) async throws where T: FDocument, U: Codable {
//			let value = document[keyPath: path]
//			let collectionName = String(describing: T.self)
//			//FIXME: - refactor out `fieldName`
//			do {
//				try await db.collection(collectionName).document(document.id).updateData([path.string: value])
//			}
//			catch let error as NSError {
//				Firappuccino.logger.error("\(error.localizedDescription)")
//				throw error
//			}
//		}
		
		public static func `write`<T, U>(to path: KeyPath<T, U>, in document: T) async throws where T: FDocument, U: Codable {
			let value = document[keyPath: path]
			let collectionName = String(describing: T.self)
			do {
				try await db.collection(collectionName).document(document.id).updateData([path.string: value])
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
//		public static func `write`<T, U>(field: FieldName, with value: U, using path: KeyPath<T, U>, in document: T) async throws where T: FDocument, U: Codable {
//			let collectionName = String(describing: T.self)
//			do {
//				try await db.collection(collectionName).document(document.id).updateData([path.string: value])
//			}
//			catch let error as NSError {
//				Firappuccino.logger.error("\(error.localizedDescription)")
//				throw error
//			}
//			//FIXME: - refactor out `fieldName`
//		}
		
		public static func `write`<T, U>(value: U, using path: KeyPath<T, U>, in document: T) async throws where T: FDocument, U: Codable {
			let collectionName = String(describing: T.self)
			do {
				print(path.string)
				try await db.collection(collectionName).document(document.id).updateData([path.string: value])
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
		
//		public static func writeAndLink<T, U>(_ document: T, toField field: FieldName, using path: KeyPath<U, [DocumentID]>, in parent: U) async throws where T: FDocument, U: FDocument {
//			//FIXME: - refactor out `fieldName`
//
//			do {
//				try await `write`(document)
//				try await Relate.`link`(document, toField: field, using: path, in: parent)
//			}
//			catch let error as NSError {
//				Firappuccino.logger.error("\(error.localizedDescription)")
//				throw error
//			}
//		}
		
		public static func writeAndLink<T, U>(_ document: T, using path: KeyPath<U, [DocumentID]>, in parent: U) async throws where T: FDocument, U: FDocument {

			do {
				try await `write`(document)
				try await Relate.`link`(document, using: path, in: parent)
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
				let _ = try await db.collection(String(describing: T.self)).document(checkID).getDocument().data(as: T.self)
				try await `write`(document)
				
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
		private static func `write`<T>(_ model: T, collection: CollectionName, id: String) async throws where T: FModel {
			do {
				async let document = db.collection(collection).document(id)
				try await document.setData(from: model)
				
				Firappuccino.logger.info("FDocument successfully `write` in [\(collection)] collection. ID: \(id)")
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
	}
	//
}
