import Logging
import FirebaseFirestore
import FirebaseFirestoreSwift

extension Firappuccino {
	
	/**
	 A service assisting with the destruction and unassignment of documents in Firestore.
	 */
	public struct Destroyer {
		
		/**
		 destroys a document in Firestore.
		 
		 - parameter id: The ID of the document to `destroy`.
		 - parameter type: The type of document to `destroy`.
		 */
		
		  public static func `destroy`<T>(id: DocumentID, ofType type: T.Type) async throws where T: FDocument {
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
		 
		 If you don't have access to your document as a local object, use ```destroy(id:ofType:)``` instead.
		 
		 - parameter document: The document to `destroy`.
		 */
		
		  public static func `destroy`<T>(_ document: T) async throws where T: FDocument {
			do {
				try await `destroy`(id: document.id, ofType: T.self)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Unassigns the document from a parent, then removes it from Firestore.
		 
		 - parameter document: The document to `unrelate` and `destroy`.
		 - parameter path: The path of the parent document's field containing the list of `DocumentID`s.
		 - parameter parent: The parent document containing the list of `DocumentID`s.
		 
		 For more information on relationships, check out `Firappuccino.Relator`.
		 */
		  public static func unrelateThenDestroy<T, U>(_ document: T, using path: ReferenceWritableKeyPath<U, [DocumentID]>, in parent: U) async throws where T: FDocument, U: FDocument {
			
			do {
				try await Relator.`unrelate`(document, using: path, in: parent)
				try await `destroy`(document)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
	}
}
