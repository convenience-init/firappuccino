
extension Firappuccino {
	
	/**
	 Allows `Firappuccino` to manage the relationship between a "parent" and "child" `FDocument` in Firestore.
	 */
	public struct Relator {
		
		/// Assigns a document's ID to a list of `DocumentID`s in the parent document.
		/// - Parameters:
		///   - child: The child document (only used to `fetch` an ID).
		///   - path: The path of the parent document's field containing the list of `DocumentID`s.
		///   - parent: The parent document containing the list of `DocumentID`s.
		public static func `relate`<T, U>(_ child: T, using path: ReferenceWritableKeyPath<U, [DocumentID]>, in parent: U) async throws where T: FDocument, U: FDocument {
			do {
				try await append(child.id, using: path, in: parent)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}

		/**
		 Removes a document's `id` from a list of `DocumentID`s in the parent document.
		 
		 - parameter child: The child document (only used to `fetch` an `id`).
		 - parameter path: The path of the parent document's field containing the list of `DocumentID`s.
		 - parameter parent: The parent document containing the list of `DocumentID`s.
		 */

		public static func `unrelate`<T, U>(_ child: T, using path: ReferenceWritableKeyPath<U, [DocumentID]>, in parent: U) async throws where T: FDocument, U: FDocument {

			do {
				try await unappend(child.id, using: path, in: parent)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		private static func append<T>(_ id: DocumentID, using path: ReferenceWritableKeyPath<T, [DocumentID]>, in parent: T) async throws where T: FDocument {

			do {
				guard var array = try await fetchArray(from: parent.id, ofType: T.self, path: path) else { throw RelationError.noParentArray }
				array <= id
				
//				var parent = parent
				parent[keyPath: path] = array
				
				try await Writer.updateField(path, in: parent, with: array)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(RelationError.noParentArray)")
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		private static func unappend<T>(_ id: DocumentID, using path: ReferenceWritableKeyPath<T, [DocumentID]>, in parent: T) async throws where T: FDocument {
			do {
				let array = try await fetchArray(from: parent.id, ofType: T.self, path: path)
				guard var array = array else { throw RelationError.noParentArray }
				array -= id
//				var parent = parent
				parent[keyPath: path] = array
				try await Writer.updateField(path, in: parent, with: array)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		enum RelationError: Error {
			case noParentArray
			case noChildObject
		}
	}
}
