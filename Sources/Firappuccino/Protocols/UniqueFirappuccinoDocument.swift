
/// The name of a `UniqueFirappuccinoDocument`.
///
/// This applies as the state object's unique identifier, as only one `UniqueFirappuccinoDocument` should exist for its given name.
public typealias UniqueFirappuccinoDocumentName = DocumentID

/**
 An unique, indexed `FirappuccinoDocument` stored in Firestore.
 
 All `UniqueFirappuccinoDocument`s are stored in a seperate collection named `UniqueDocument`. Each `UniqueFirappuccinoDocument` should have a unique `Type`, and only one `UniqueFirappuccinoDocument` of each `Type` should exist within the `UniqueDocument` collection.
 
 `UniqueFirappuccinoDocument`s can be stored in Firestore using `Firappuccino.CloudStore`.
 */
public protocol UniqueFirappuccinoDocument: FirappuccinoDocument {
	
	/// The name of the unique document.
	var id: UniqueFirappuccinoDocumentName { get set }
}

public extension UniqueFirappuccinoDocument {
	
}
