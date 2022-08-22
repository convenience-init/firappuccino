
extension Firappuccino {
	
	/**
	 Allows `Firappuccino` to manage the relationship between a "parent" and "child" `FirappuccinoDocument` in Firestore.
	 */
	public struct Relationship {
		
		/// Assigns a document's ID to a list of `DocumentID`s in the parent document.
		/// - Parameters:
		///   - child: The child document (only used to get an ID).
		///   - field: The name of the field in the parent document.
		///   - path: The path of the parent document's field containing the list of `DocumentID`s.
		///   - parent: The parent document containing the list of `DocumentID`s.
		public static func assign<T, U>(_ child: T, toField field: FieldName, using path: KeyPath<U, [DocumentID]>, in parent: U) async throws where T: FirappuccinoDocument, U: FirappuccinoDocument {
			
			do {
				try await append(child.id, field: field, using: path, in: parent)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		/**
		 Un-assigns a document's ID from a list of `DocumentID`s in the parent document.
		 
		 - parameter child: The child document (only used to get an ID).
		 - parameter path: The path of the parent document's field containing the list of `DocumentID`s.
		 - parameter parent: The parent document containing the list of `DocumentID`s.
		 - parameter completion: The completion handler.
		 */
		
		public static func unassign<T, U>(_ child: T, fromField field: FieldName, using path: KeyPath<U, [DocumentID]>, in parent: U) async throws where T: FirappuccinoDocument, U: FirappuccinoDocument {
			
			do {
				try await unappend(child.id, field: field, using: path, in: parent)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		private static func append<T>(_ id: DocumentID, field: FieldName, using path: KeyPath<T, [DocumentID]>, in parent: T) async throws where T: FirappuccinoDocument {
			do {
				guard var array = try await getArray(from: parent.id, ofType: T.self, path: path)  else { throw RelationshipError.noArray }
				array <= id
				try await CloudStore.set(field: field, with: array, using: path, in: parent)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(RelationshipError.noArray)")
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		private static func unappend<T>(_ id: DocumentID, field: FieldName, using path: KeyPath<T, [DocumentID]>, in parent: T) async throws where T: FirappuccinoDocument {
			do {
				async let array = try await getArray(from: id, ofType: T.self, path: path)
				guard var array = try await array else { throw RelationshipError.noArray }
				array -= id
				try await CloudStore.set(field: field, with: array, using: path, in: parent)
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
				throw error
			}
		}
		
		enum RelationshipError: Error {
			case noArray
		}
	}
}
