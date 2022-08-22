import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

extension Firappuccino {
	
	/**
	 A service used for increment updates to objects in Firestore.
	 */
	public struct Counter {
				
		/**
		 Increments a value for a particular field in Firestore.
		 
		 - parameter path: The path to the document's field to update.
		 - parameter increase: The amount to increase.
		 - parameter document: The document with the updated field.
		 - parameter completion: The completion handler.
		 */
		
		public static func increment<T, U>(_ path: KeyPath<T, U>, by amount: Int, in document: T) async throws where T: FirappuccinoDocument, U: AdditiveArithmetic {
			do {
				let collectionName = String(describing: T.self)
				try await db.collection(collectionName).document(document.id).updateData([path.string: FieldValue.increment(Int64(amount))])
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
			}
		}
	}
}
