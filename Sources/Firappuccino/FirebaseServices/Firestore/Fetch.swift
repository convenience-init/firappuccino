import Logging
import FirebaseFirestore
import FirebaseFirestoreSwift

extension Firappuccino {
	
	/**
	 A service used to retrieve documents from Firestore.
	 */
	public struct Fetch {
		
		/**
		 Gets a document from Firestore.
		 
		 - parameter id: The ID of the document to retrieve.
		 - parameter type: The document's type.
		 - parameter useCache: Whether the cache should be prioritized to grab documents (if they exist).
		 - parameter completion: The completion handler.
		 
		 Objects retrieved from Firestore are retrieved from collections based on their type.
		 */
		
		public static func `fetch`<T>(id: DocumentID, ofType type: T.Type, useCache: Bool = Configurator.useCache) async throws -> T? where T: FDocument {
			if useCache, let cachedDocument = try await LocalCache.`cacheFetch`(id, fromType: type) {
				return cachedDocument
			}
			else {
				return try await `fetch`(id, collection: colName(of: T.self), type: type)
			}
		}
		
		/**
		 Fetches a `Individuatable` from the collection of the same name in Firestore.
		 
		 */
		
		public static func `fetch`<T>(uniqueDocument: IndividuatableName, ofType type: T.Type) async throws -> T? where T: Individuatable {
			return try await `fetch`(uniqueDocument, collection: "Individuatable", type: type)
		}
		
		/**
		 Gets an array of documents from Firestore.
		 
		 - parameter ids: An array of `DocumentID`s to retrieve.
		 - parameter type: The documents' type.
		 - parameter useCache: Whether the cache should be prioritized to grab documents (if they exist).
		 - parameter onFetch: The fetch handler. When documents are fetched, they'll populate here.
		 */
		public static func `fetch`<T>(ids: [DocumentID], ofType type: T.Type, useCache: Bool = Configurator.useCache) async throws -> [T] where T: FDocument {
			
			var results: [T] = []
			guard ids.count > 0 else { return results }
			async let chunks = ids.chunk(size: 10)
			
			do {
				for chunk in await chunks {
					results <= (try await `fetch`(chunk: chunk, ofType: type, useCache: useCache))
					
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
		 - parameter useCache: Whether the cache should be prioritized to grab documents (if they exist).
		 */
		public static func fetchChildren<T, U>(from path: KeyPath<U, [DocumentID]>, in parent: U, ofType: T.Type, useCache: Bool = Configurator.useCache) async throws -> [T] where T: FDocument, U: FDocument {
			
			do {
				async let childrenIds = try await Firappuccino.fetchArray(from: parent.id, ofType: U.self, path: path)
				guard let ids = try await childrenIds else { return [] }
				async let children = try await `fetch`(ids: ids, ofType: T.self)
				return try await children
				
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		private static func `fetch`<T>(_ id: String, collection: CollectionName, type: T.Type) async throws -> T? where T: FDocument {
			do {
				async let fetchedDocument = try await db.collection(collection).document(id).getDocument().data(as: type)
				try await LocalCache.register(try await fetchedDocument)
				return try await fetchedDocument
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		private static func `fetch`<T>(chunk: [DocumentID], ofType type: T.Type, useCache: Bool) async throws -> [T] where T: FDocument {
			var cachedDocuments: [T] = []
			guard chunk.count > 0, chunk.count <= 10 else { return cachedDocuments }
			
			do {
				var newIDs: [DocumentID] = chunk
				if useCache {
					for id in chunk {
						if let cachedDocument = try await LocalCache.`cacheFetch`(id, fromType: T.self) {
							cachedDocuments <= cachedDocument
							newIDs -= id
						}
					}
				}
				
				guard newIDs.count > 0 else { return cachedDocuments }
				let results: [T] = try await db.collection(colName(of: T.self)).whereField("id", in: newIDs).getDocuments().documents.compactMap({try $0.data(as: T.self)})
				for doc in results {
					try await LocalCache.register(doc)
				}
				return results
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
	}
}
