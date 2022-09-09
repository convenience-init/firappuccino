
/// The ID of a document.
public typealias DocumentID = String

/**
 An `Document` object that can be stored in and managed by Firestore.
 
 Adopt the `FirappuccinoDocument` protocol to send your own custom data objects.
 
 All documents must have `id`, `dateCreated` properties, as well as a way to check for equality:
 
 ```swift
 class Post: FirappuccinoDocument {
 
 var id: String
 var dateCreated: Date = Date()
 
 var title: String
 var body: String
 
 static func == (lhs: Post, rhs: Post) -> Bool {
 return lhs.id == rhs.id
 }
 
 init(id: String, title: String, body: String) {
 self.id = id
 self.title = title
 self.body = body
 }
 }
 ```
 
 Once you've instantiated documents, you can easily perform various database operations inline using `KeyPath`s.
 
 ````
 // Create `stupidApeOne` and `stupidApeToo` `DumbNFT` objects:
 var stupidApeOne = DumbNFT(id: "0", name: "stupidApeOne", price: 250_000)
 var stupidApeToo = DumbNFT(id: "1", name: "stupidApeToo", price: 150_000)
 
 // Set the price of `stupidApeToo` to 200_000 in ``Firestore``
 stupidApeToo.`write`(200_000, to: \.price)
 
 // Fetch the most up-to-date price info for `stupidApeOne`
 do {
 	let currentPrice = try await stupidApeOne.`fetch`(\.price)
 	print("StupidApeOne will currently set you back \(currentPrice)")
 }
 catch {
 	//...
 }

 ```
 */
public protocol FDocument: FModel, Equatable, Identifiable {
	
	/// The document's unique identifier.
	///
	/// It's important to note that documents with identical IDs will be merged when sent to Firestore.
	///
	/// To avoid this, it's advisable to assign `UUID().uuidStringSansDashes` as the default value when creating new documents.
	var id: String { get set }
	
	/// The date the document was created.
	///
	/// This field is assigned manually. It's recommended to assign a new `Date()` instance.
	var dateCreated: Date { get }
}

extension FDocument {
	
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		return lhs.id == rhs.id
	}
}

extension FDocument {
	
	/**
	 Sets the document in Firestore.
	 
	 Documents are automatically stored in collections based on their type.
	 
	 If the document to be `write` has the same ID as an existing document in a collection, the old document will be overwritten.
	 */
	public func `write`() async throws {
		do {
			try await Firappuccino.FStore.`write`(self)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	/**
	 Updates a specific field remotely in Firestore.
	 
	 - parameter path: The path to the field to update remotely.
	 */
	
	/// Sets a specific field of a document remotely in Firestore.
	/// - Parameters:
	///   - field: The name of the field
	///   - path: The path to th document containing the field
	///   - ofType: The `Type` of the document to be updated.
	public func `write`<T, U>(field: FieldName, using path: KeyPath<T, U>, ofType: T.Type) async throws where T: FDocument, U: Codable {
		try await Firappuccino.FStore.`write`(field: field, using: path, in: self as! T)
	}
	
	
	/**
	 Updates a specific field with a new value both locally and remotely in Firestore.
	 
	 - parameter value: The new value.
	 - parameter path: The path to the field to update.
	 */
	public mutating func `write`<T>(field: FieldName, with value: T, using path: WritableKeyPath<Self, T>) async throws where T: Codable {
		self[keyPath: path] = value
		//FIXME: - refactor out `fieldName`
		do {
			try await Firappuccino.FStore.`write`(field: field, with: value, using: path, in: self)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
		}
	}
	
	/**
	 Increments a specific field remotely in Firestore.
	 
	 - parameter path: The path to the field to update.
	 - parameter increment: The amount to increment by.
	 - parameter completion: The completion handler.
	 */
	public mutating func increment<T>(_ path: WritableKeyPath<Self, T>, by increment: T) async throws where T: AdditiveArithmetic {
		do {
			var fieldValue = self[keyPath: path]
			if let incrementAmount = increment as? Int {
				try await Firappuccino.Stride.increment(path, by: incrementAmount, in: self)
				fieldValue.add(increment)
				self[keyPath: path] = fieldValue
			}
		}
		catch let error as NSError {
			Firappuccino.logger.error("You can't increment mismatching values!")
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	/**
	 Gets the most up-to-date value from a specified path.
	 
	 - parameter path: The path to the field to retrieve.
	 - parameter completion: The completion handler.
	 
	 If you don't want to update the entire object, and instead you just want to fetch a particular value, this method may be helpful.
	 */
	public func `fetch`<T>(_ path: KeyPath<Self, T>) async throws -> T? where T: Codable {
		guard let document = try await Firappuccino.Fetch.`fetch`(id: id, ofType: Self.self) else { return nil }
		return document[keyPath: path]
		
	}
	
	
	/// Assigns the specified "child" `FDocument`'s ID to a collection of DocumentIDs in a "parent" `FDocument` document in Firestore.
	/// - Parameters:
	///   - field: The name of the "target" field in the parent `FDocument`.
	///   - path: The path to the `field` of `DocumentID`s in the parent `FDocument`.
	///   - parent: The parent `FDocument` containing the field of `DocumentID`s
	///   - remark: If `draftPosts` is a property of a `FUser` object  instance, calling
	///   ```post.assign(to: \.draftPosts, in: user)```
	///   will add the `post`'s ID to `users`'s `draftPosts`.
	///  - important: Fields will not be updated locally using this method.
	public func `link`<T>(toField field: FieldName, using path: KeyPath<T, [DocumentID]>, in parent: T) async throws where T: FDocument {
		
		do {
			try await Firappuccino.Relate.`link`(self, toField: field, using: path, in: parent)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	
	///  Sets the document in Firestore, then assigns it to a field list of `DocumentID`s to a parent document.
	/// - Parameters:
	///   - field: field description
	///   - path: path description
	///   - parent: parent description
	public func writeAndLink<T>(toField field: FieldName, using path: KeyPath<T, [DocumentID]>, in parent: T) async throws where T: FDocument {
		do {
			try await Firappuccino.FStore.writeAndLink(self, toField: field, using: path, in: parent)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	
	/// Unassigns the document's ID from a related list of IDs in another document.
	/// - Parameters:
	///   - field: field description
	///   - path: path description
	///   - parent: parent description
	public func unlink<T>(fromField field: FieldName, using path: KeyPath<T, [DocumentID]>, in parent: T) async throws where T: FDocument {
		do {
			try await Firappuccino.Relate.`unlink`(self, fromField: field, using: path, in: parent)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
}

