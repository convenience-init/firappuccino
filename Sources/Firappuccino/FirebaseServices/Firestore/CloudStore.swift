import FirebaseFirestore
import FirebaseFirestoreSwift

public typealias FieldName = String

extension Firappuccino {
	
	/**
	 The `CloudStore` lets `Firappuccino` handle the management of your `FirappuccinoDocument` stored remotely in your ``Firestore`` database.
	 */
	public struct CloudStore {
		
		/**
		 Sets a document in Firestore.
		 
		 - parameter document: The document to set in Firestore.
		 */
		
		public static func set<T>(_ document: T) async throws where T: FirappuccinoDocument {
			do {
				try await set(document, collection: document.typeName, id: document.id)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Sets a `UniqueFirappuccinoDocument` in Firestore.
		 
		 - parameter stateObject: The singleton to set in Firestore.
		 - parameter completion: The completion handler.
		 */
		
		public static func set<T>(_ uniqueDocument: T) async throws where T: UniqueFirappuccinoDocument {
			do {
				try await set(uniqueDocument, collection: "UniqueDocument", id: uniqueDocument.id)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Updates a value for a particular field in Firestore.
		 
		 - parameter path: The path to the document's field to update.
		 - parameter document: The document with the updated field.
		 - parameter completion: The completion handler.
		 */
		public static func set<T, U>(field: FieldName, using path: KeyPath<T, U>, in document: T) async throws where T: FirappuccinoDocument, U: Codable {
			let value = document[keyPath: path]
			let collectionName = String(describing: T.self)
			
			do {
				try await db.collection(collectionName).document(document.id).updateData([field: value])
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Updates a value for a particular field in Firestore.
		 
		 - parameter value: The new value to update.
		 - parameter path: the path to the document's field in Firestore.
		 - parameter document: The document with the field to update.
		 - parameter completion: The completion handler.
		 */
		public static func set<T, U>(field: FieldName, with value: U, using path: KeyPath<T, U>, in document: T) async throws where T: FirappuccinoDocument, U: Codable {
			let collectionName = String(describing: T.self)
			do {
				try await db.collection(collectionName).document(document.id).updateData([field: value])
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Sets the object in Firestore, then assigns it to a parent document's field list of `DocumentID`s.
		 
		 - parameter document: The document to store in Firestore.
		 - parameter child: The child document (only used to get an ID).
		 - parameter path: The path of the parent document's field containing the list of `DocumentID`s.
		 - parameter parent: The parent document containing the list of `DocumentID`s.
		 - parameter completion: The completion handler.
		 */
		
		public static func setAssign<T, U>(_ document: T, toField field: FieldName, using path: KeyPath<U, [DocumentID]>, in parent: U) async throws where T: FirappuccinoDocument, U: FirappuccinoDocument {
			
			do {
				try await set(document)
				try await Relationship.assign(document, toField: field, using: path, in: parent)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Sets a (default) document in Firestore only if the document does not exist.
		 
		 This method is used to create new documents in Firestore without being destructive. For instance, if user objects have other document types unique to them, you may want to create these new documents under the condition that they don't already exist to prevent user data loss.
		 
		 - parameter document: The document to set in Firestore.
		 - parameter id: The ID of the document to check in Firestore. If set to `nil`, the ID of the document being set will be used to check.
		 */
		
		public static func setIfNone<T>(_ document: T, checking id: DocumentID? = nil) async throws where T: FirappuccinoDocument {
			
			var checkID = document.id
			if let id = id {
				checkID = id
			}
			
			do {
				let _ = try await db.collection(String(describing: T.self)).document(checkID).getDocument().data(as: T.self)
				try await `set`(document)
				
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/// Sets a passed `FirappuccinoDocument` in `Firestore` remote db
		/// - Parameters:
		///   - model: An object of `Type` that adopts `FirappuccinoDocumentModel`.
		///   - collection: The `String` name of the collection to set the document
		///   - id: The `id` of the document to set
		private static func set<T>(_ model: T, collection: CollectionName, id: String) async throws where T: FirappuccinoDocumentModel {
			do {
				async let document = db.collection(collection).document(id)
				try await document.setData(from: model)
				
				Firappuccino.logger.info("FirappuccinoDocument successfully set in [\(collection)] collection. ID: \(id)")
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
	}
	//
}
