import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

extension Firappuccino {
	
	/**
	 A service used for incrementField updates to objects in Firestore.
	 */
	public struct Updater {
				
		/**
		 Increments a value for a particular field in Firestore.
		 
		 - parameter path: The path to the document's field to update.
		 - parameter increase: The amount to increase.
		 - parameter document: The document with the updated field.
		 */
		public static func incrementField<T, U>(_ path: ReferenceWritableKeyPath<T, U>, by increase: Int, in document: T) async throws where T: FDocument, U: AdditiveArithmetic {
			let currentValue = document[keyPath: path]
			do {
				let collectionName = String(describing: T.self)
				let fieldName = path.fieldName
				try await db.collection(collectionName).document(document.id).updateData([fieldName: FieldValue.increment(Int64(increase))])
				document[keyPath: path] = (currentValue as! Int + increase) as! U
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
			}
		}
	}
	
		/**
		 Updates a value for a particular field in Firestore.
	
		 - parameter path: The path to the document's field to update.
		 - parameter document: The document with the updated field.
		 */
//		public static func update<T, U>(field: FieldName, using path: ReferenceWritableKeyPath<T, U>, in document: T, completion: @escaping (Error?) -> Void = { _ in }) where T: FDocument, U: Codable {
//			var document = document
//			let value = document[keyPath: path]
//			let collectionName = String(describing: T.self)
//			db.collection(collectionName).document(document.id).updateData([field: value], completion: completion)
//			document[keyPath: path] = value
//		}
}
