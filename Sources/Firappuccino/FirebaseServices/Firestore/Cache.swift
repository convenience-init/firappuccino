
extension Firappuccino {
	
	/**
	 The `FirappuccinoCache` lets `Firappuccino` manage the the local cacheing of your objects stored in Firestore.
	 
	 You can specify whether you'd like to use `Firappuccino`'s cacheing capabilities by setting the static `useCache` property to `true` in your apps `AppDelegate`.
	 
	 ````
	 Firappuccino.useCache = true
	 ````
	 */
	public struct LocalCache {
		
		fileprivate static var caches: [CollectionName: Any] = [:]
		
		/**
		 Registers a `FirappuccinoDocument` to the cache.
		 
		 - parameter document: The document to register.
		 
		 If `Firappuccino.useCache` is set to `true`, documents retrieved from Firestore using `Firappuccino.Fetch` are automatically cached.
		 
		 To retrieve a cached object, use ```grab(_:fromType:)```.
		 - note: Registered documents are stored in caches based on their `Type`.
		 */
		public static func register<T>(_ document: T) async throws where T: FirappuccinoDocument {
			do {
				async let cache = LocalCache.caches[document.typeName] as! Cache<T>
				try await cache.register(document)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
			}
		}
		
		/**
		 Fetches a cached `Firappuccino` from the cache.
		 
		 - parameter id: The ID of the document to grab.
		 - parameter type: The document's type.
		 
		 You can specify whether you'd like to retrieve cached documents when retrieving objects with `Firappuccino.Fetch`.
		 
		 To store a local document, use ```register(_:)```.
		 - note: Registered documents are stored in caches based on their `Type`.
		 */
		public static func grab<T>(_ id: DocumentID, fromType type: T.Type) async throws -> T? where T: FirappuccinoDocument {
			var cached: T? = nil
			do {
				async let cache = (LocalCache.caches[colName(of: T.self)] as! Cache<T>).grab(id)
				if let cache = try await cache {
					cached = cache
				}
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
			}
			return cached
		}
	}
	
	/**
	 A local cache for documents of a specified `Type`.
	 */
	public class Cache<T> where T: FirappuccinoDocument {
		
		private var cache: [DocumentID: T] = [:]
		
		/// Gets a document with the specified `id` from the cache if it exists.
		/// - Parameter id: The `DocumentID` of the target document.
		/// - Returns: An object conforming to `FirappuccinoDocument` or `nil`
		fileprivate func grab(_ id: DocumentID) async throws -> T? where T: FirappuccinoDocument {
			guard let document = cache[id] else { return nil }
			Firappuccino.logger.info("FirappuccinoDocument successfully retrieved from [\(document.typeName)] cache. ID: \(id)")
			return cache[id]
		}
		
		/// Registers a remote `FirappuccinoDocument` in the local cache
		/// - Parameter document: The document to register.
		fileprivate func register(_ document: T) async throws where T: FirappuccinoDocument {
			cache[document.id] = document
			Firappuccino.logger.info("FirappuccinoDocument successfully stored in [\(document.typeName)] cache. ID: \(document.id) Size: \(cache.count) object(s)")
		}
	}
}
