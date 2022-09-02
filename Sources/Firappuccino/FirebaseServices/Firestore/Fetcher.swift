import Logging
import FirebaseFirestore
import FirebaseFirestoreSwift

extension Firappuccino {
	
	/**
	 A service used to retrieve documents from Firestore.
	 */
	public struct Fetcher {
		/**
		 Gets a document from Firestore.
		 
		 - parameter id: The ID of the document to retrieve.
		 - parameter type: The document's type.
		 
		 Objects retrieved from Firestore are retrieved from collections based on their type.
		 */
		
		public static func `fetch`<T>(id: DocumentID, ofType type: T.Type) async throws -> T? where T: FDocument {
			do {
				return try await `fetch`(id, collection: colName(of: T.self), type: type)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Gets an array of documents from Firestore.
		 
		 - parameter ids: An array of `DocumentID`s to retrieve.
		 - parameter type: The documents' type.
		 */
		//FIXME: add onFetch handler
		public static func `fetch`<T>(ids: [DocumentID], ofType type: T.Type) async throws -> [T] where T: FDocument {
			
			var results: [T] = []
			guard ids.count > 0 else { return results }
			let chunks = ids.chunk(size: 10)
			
			do {
				for chunk in chunks {
					results <= (try await `fetch`(chunk: chunk, ofType: type))
					
				}
				return results
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Gets an array of documents from Firestore based on a list of `DocumentID`s from some parent document.
		 
		 - parameter path: The path of the parent document's field containing the list of `DocumentID`s.
		 - parameter parent: The parent document containing the list of `DocumentID`s.
		 - parameter type: The type of documents that are being retrieved.
		 */
		public static func fetchChildren<T, U>(from path: KeyPath<U, [DocumentID]>, in parent: U, ofType: T.Type) async throws -> [T] where T: FDocument, U: FDocument {
			
			do {
				let childrenIds = try await Firappuccino.fetchArray(from: parent.id, ofType: U.self, path: path)
				guard let ids = childrenIds else { return [] }
				let children = try await `fetch`(ids: ids, ofType: T.self)
				return children
				
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		private static func `fetch`<T>(_ id: String, collection: CollectionName, type: T.Type) async throws -> T? where T: FDocument {
			do {
				return try await db.collection(collection).document(id).getDocument().data(as: type)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		private static func `fetch`<T>(chunk: [DocumentID], ofType type: T.Type) async throws -> [T] where T: FDocument {
			guard chunk.count > 0, chunk.count <= 10 else { return [] }
			
			do {
				guard chunk.count > 0 else { return [] }
				return try await db.collection(colName(of: T.self)).whereField("id", in: chunk).getDocuments().documents.compactMap({try $0.data(as: T.self)})
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
	}
}
