import Foundation
import Logging
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

/// The name of a collection.
public typealias CollectionName = String

public struct Firappuccino {
	
	public static let sender = LegacyFPNSender()
	
	public static let logger = Logger(label: "uno.cuatrotresdos.firappuccino.main")
	
	/// The `Firestore` Database
	public static let db = Firestore.firestore()
	
	/// Fetches the contents of an `Array` field from a `FDocument` stored in `Firestore`.
	/// - Parameters:
	///   - id: The `DocumentID` of the `FDocument` that contains the target `Array`
	///   - type: The object `Type` of the target `FDocument`.
	///   - path: The storage path of the target `FDocument`.
	/// - Returns: An `Array` of `DocumentID`s
	internal static func fetchArray<T>(from id: DocumentID, ofType type: T.Type, path: KeyPath<T, [DocumentID]>) async throws -> [DocumentID]? where T: FDocument {
		
		do {
			let result = try await db.collection(colName(of: T.self)).document(id).getDocument()
			let document = try result.data(as: T.self)
			let array = document[keyPath: path]
			return array
		}
		catch let error as NSError {
			Firappuccino.logger.info("Failed to load array of IDs from document [\(id)].")
			Firappuccino.logger.error( "\(error.localizedDescription)")
			return []
		}
	}
	
	/// Standardizes naming of `Firestore` Collections by using the `String` representation of the `Type` of object to be stored within it.
	/// - Parameter type: the `Type` of the object to be stored.
	/// - Returns: A `String` reresentation of the passed object's `Type`.
	public static func colName<T>(of type: T.Type) -> CollectionName {
		var string = String(describing: T.self)
		if let dotRange = string.range(of: ".") {
			string.removeSubrange(string.startIndex ..< dotRange.lowerBound)
		}
		return string
	}
}
