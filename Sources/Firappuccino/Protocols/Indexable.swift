import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

/**
 A document that is indexed using a counter.
 
 Each new document that is created and pushed to Firestore has a unique index determined by an associated `Individuatable` that is automatically created when the indexed document is created.
 */
public protocol FIndexable: FDocument {
	
	/// The document's index.
	///
	/// If the document has not yet been written to Firestore, this value will be `nil`.
	var index: Int? { get set }
}

public extension FIndexable {
	
	/**
	 Sets the document in Firestore and updates the corresponding unique index document.
	 
	 `FIndexable` documents are automatically stored in collections based on their type.
	 
	 - important: If the pushed document has the same ID as an existing document in a collection, the old document will be replaced.
	 */
	func `writeAndIndex`() async throws {
		do {
			async let newSelf = Self.prepare(self)
			try await Firappuccino.FStore.`write`(try await newSelf)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
}

private extension FIndexable {
	
	static func indexedDocument() async throws -> DocumentReference {
		Firestore.firestore().collection("Individuatable").document("_indexCount")
	}
	
	static func prepare<T>(_ document: T) async throws -> T where T: FIndexable {
		
		var newDocument: T = document
		
		let fieldName = String(describing: Self.self)
		
		guard document.index == nil else {
			return document
		}
		
		do {
			let snapshot = try await indexedDocument().getDocument()
			
			newDocument.index = 0
			
			if let count = snapshot.data()?[fieldName] as? Int {
				newDocument.index = count + 1
			}
			try await indexedDocument().setData([fieldName: newDocument.index!])
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
		return newDocument
	}
}
