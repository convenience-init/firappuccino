
//extension Firappuccino {
//	
//	/**
//	 The `FCache` lets `Firappuccino` manage the the local cacheing of your objects stored in Firestore.
//	 
//	 You can specify whether you'd like to use `Firappuccino`'s cacheing capabilities by setting the static `useCache` property to `true` in your apps `AppDelegate`.
//	 
//	 ````
//	 Configurator.useCache = true
//	 ````
//	 */
//	public struct LocalCache {
//		
//		fileprivate static var caches: [CollectionName: Any] = [:]
//		
//		/**
//		 Registers a `FDocument` to the cache.
//		 
//		 - parameter document: The document to register.
//		 
//		 If `Configurator.useCache` is set to `true`, documents retrieved from Firestore using `Firappuccino.Fetch` are automatically cached.
//		 
//		 To retrieve a cached object, use ```cacheFetch(_:fromType:)```.
//		 - note: Registered documents are stored in caches based on their `Type`.
//		 */
//		public static func register<T>(_ document: T) async throws where T: FDocument {
//			do {
//				async let cache = LocalCache.caches[document.typeName] as? FCache<T>
//				try await cache?.register(document)
//			}
//			catch let error as NSError {
//				Firappuccino.logger.error("\(error.localizedDescription)")
//			}
//		}
//		
//		/**
//		 Fetches a object from the cache if it is present.
//		 
//		 - parameter id: The ID of the document to grab.
//		 - parameter type: The document's type.
//		 
//		 You can specify whether you'd like to retrieve cached documents when retrieving objects with `Firappuccino.Fetch`.
//		 
//		 To store a local document, use ```register(_:)```.
//		 - note: Registered documents are stored in caches based on their `Type`.
//		 */
//		public static func `cacheFetch`<T>(_ id: DocumentID, fromType type: T.Type) async throws -> T? where T: FDocument {
//			var cached: T? = nil
//			do {
//				async let cache = (LocalCache.caches[colName(of: T.self)] as! FCache<T>).`cacheFetch`(id)
//				if let cache = try await cache {
//					cached = cache
//				}
//			}
//			catch let error as NSError {
//				Firappuccino.logger.error("\(error.localizedDescription)")
//			}
//			return cached
//		}
//	}
//	
//	/**
//	 A local cache for documents of a specified `Type`.
//	 */
//	public class FCache<T> where T: FDocument {
//		
//		private var cache: [DocumentID: T] = [:]
//		
//		/// Gets a document with the specified `id` from the cache if it exists.
//		/// - Parameter id: The `DocumentID` of the target document.
//		/// - Returns: An object conforming to `FDocument` or `nil`
//		fileprivate func `cacheFetch`(_ id: DocumentID) async throws -> T? where T: FDocument {
//			guard let document = cache[id] else { return nil }
//			Firappuccino.logger.info("FDocument successfully retrieved from [\(document.typeName)] cache. ID: \(id)")
//			return cache[id]
//		}
//		
//		/// Registers a remote `FDocument` in the local cache
//		/// - Parameter document: The document to register.
//		fileprivate func register(_ document: T) async throws where T: FDocument {
//			cache[document.id] = document
//			Firappuccino.logger.info("FDocument successfully stored in [\(document.typeName)] cache. ID: \(document.id) Size: \(cache.count) object(s)")
//		}
//	}
//}
