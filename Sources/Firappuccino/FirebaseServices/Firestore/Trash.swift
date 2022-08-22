import Logging
import FirebaseFirestore
import FirebaseFirestoreSwift

extension Firappuccino {
	
	/**
	 A service assisting with the removal and unassignment of documents in Firestore.
	 */
	public struct Trash {
		
		/**
		 Removes a document from its collection in Firestore.
		 
		 If you have the document you'd like to remove as a local object, consider using ``remove(_:completion:)`` to simplify your code.
		 
		 - parameter id: The ID of the document to remove.
		 - parameter type: The type of document to remove.
		 - parameter completion: The completion handler.
		 */
		
		@MainActor public static func remove<T>(id: DocumentID, ofType type: T.Type) async throws where T: FirappuccinoDocument {
			do {
				let collectionName = String(describing: T.self)
				try await db.collection(collectionName).document(id).delete()
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Removes a document from its collection in Firestore.
		 
		 If you don't have access to your document as a local object, consider using ``remove(id:ofType:completion:)``.
		 
		 - parameter document: The document to remove.
		 - parameter completion: The completion handler.
		 */
		
		@MainActor public static func remove<T>(_ document: T) async throws where T: FirappuccinoDocument {
			do {
				try await remove(id: document.id, ofType: T.self)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Unassigns the document from a parent in Firestore, then removes the document from its collection in Firestore.
		 
		 - parameter document: The document to unassign and remove.
		 - parameter path: The path of the parent document's field containing the list of `DocumentID`s.
		 - parameter parent: The parent document containing the list of `DocumentID`s.
		 - parameter completion: The completion handler.
		 
		 For more information on unassignment, check out `Firappuccino.Relationship`.
		 */
		
		@MainActor public static func unassignThenRemove<T, U>(_ document: T, fromField field: FieldName, using path: KeyPath<U, [DocumentID]>, in parent: U) async throws where T: FirappuccinoDocument, U: FirappuccinoDocument {
			
			do {
				try await Relationship.unassign(document, fromField: field, using: path, in: parent)
				try await remove(document)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
	}
}
