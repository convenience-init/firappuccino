
extension Firappuccino {
	
	/**
	 The `Cacher` lets `Firappuccino` manage the the local cacheing of your objects stored in Firestore.
	 */
	public struct Cacher {
		fileprivate static var caches: [CollectionName: Any] = [:]
		
		/**
		 Registers a `FDocument` to the fCache.
		 
		 - parameter document: The document to register.
		 
		 If `Configurator.useCache` is set to `true`, documents retrieved from Firestore using `Firappuccino.Fetcher` are automatically cached.
		 
		 To retrieve a cached object, use ```fetchCached`(_:fromType:)```.
		 - note: Registered documents are stored in caches based on their `Type`.
		 */
		public static func register<T>(_ document: T) async throws where T: FDocument {
			do {
				async let cache = Cacher.caches[document.typeName] as? LocalFCache<T>
				try await cache?.register(document)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
			}
		}
		
		/**
		 Fetches a object from the fCache if it is present.
		 
		 - parameter id: The ID of the document to grab.
		 - parameter type: The document's type.
		 
		 You can specify whether you'd like to retrieve cached documents when retrieving objects with `Firappuccino.Fetcher`.
		 
		 To store a local document, use ```register(_:)```.
		 - note: Registered documents are stored in caches based on their `Type`.
		 */
		public static func `fetchCached`<T>(_ id: DocumentID, fromType type: T.Type) async throws -> T? where T: FDocument {
			var cached: T? = nil
			do {
				let cache = try await (Cacher.caches[Firappuccino.colName(of: T.self)] as? LocalFCache<T>)?.`cacheFetch`(id)
				if let cache = cache {
					cached = cache
				}
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
			}
			return cached
		}
		//
		//	/**
		//	 A local cache for documents of a specified `Type`.
		//	 */
		public class LocalFCache<T> where T: FDocument {
			
			private var fCache: [DocumentID: T] = [:]
			
			/// Gets a document with the specified `id` from the fCache if it exists.
			/// - Parameter id: The `DocumentID` of the target document.
			/// - Returns: An object conforming to `FDocument` or `nil`
			fileprivate func `cacheFetch`(_ id: DocumentID) async throws -> T? where T: FDocument {
				guard let document = fCache[id] else { return nil }
				Firappuccino.logger.info("FDocument successfully retrieved from [\(document.typeName)] cache. ID: \(id)")
				return fCache[id]
			}
			
			/// Registers a remote `FDocument` in the local fCache
			/// - Parameter document: The document to register.
			fileprivate func register(_ document: T) async throws where T: FDocument {
				fCache[document.id] = document
				Firappuccino.logger.info("FDocument successfully stored in [\(document.typeName)] cache. ID: \(document.id) Size: \(fCache.count) object(s)")
			}
		}
	}
}
