
/// The name of an `Individuatable` object.
///
/// This applies as the state object's unique identifier, as only one `UniqueFDocument` should exist for its given name.
public typealias IndividuatableName = DocumentID

/**
 A unique, indexed `FDocument` stored in Firestore.
 
 All `Individuatable`s are stored in a seperate collection named `Individuatable`. Each `Individuatable` should have a unique `Type`, and only one `Individuatable` of each `Type` should exist within the `Individuatable` collection.
 
 `Individuatable`s can be stored in Firestore using `Firappuccino.Write`.
 */
public protocol Individuatable: FDocument {
	
	/// The name of the unique document.
	var id: IndividuatableName { get set }
}

//TODO: - see: https://stackoverflow.com/a/59892127
public extension Individuatable {
	
}
