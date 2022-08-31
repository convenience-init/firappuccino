
/// The ID of a document.
public typealias DocumentID = String

/**
 A Firestore-compatible document.
 
 Adopt the `FDocument` protocol to send your own custom document models.
 
 All documents must have `id`, `createdAt` properties, as well as a way to check for equality:
 
 ```swift
 class Post: FirappuccinoDocument {
 
 var id: String
 var createdAt: Date = Date()
 
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
 
 // Fetcher the most up-to-date price info for `stupidApeOne`
 do {
 	let currentPrice = try await stupidApeOne.`fetch`(\.price)
 	print("StupidApeOne will currently set you back \(currentPrice)")
 }
 catch {
 	//...
 }

 ```
 */
public protocol FDocument: FModel, Identifiable, Equatable {
	
	/// The document's unique identifier.
	///
	/// -important: FDocuments with identical IDs will be merged when sent to Firestore.
	///
	/// To avoid this, it's advisable to assign `UUID().uuidStringSansDashes` as the default value when creating new documents.
	///
	var id: String { get set }
	
	/// The date the document was created.
	/// This field is assigned manually. It's recommended to assign a new `Date()` instance.
	var createdAt: Date { get }
}

extension FDocument {
	
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		return lhs.id == rhs.id
	}
}

extension FDocument {
	
	/**
	 Writes the document to Firestore.
	 
	 Documents are automatically stored in collections named the same as their type.
	 
	 If the document to be written has the same ID as an existing document in a collection, the old document will be overwritten.
	 */
	public func `write`() async throws {
		do {
			try await Firappuccino.Writer.`write`(self)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	/**
	 Writes a value to a document field located at the specified keyPath.
	 
	 - parameter value: The new value.
	 - parameter path: The keyPath to the field.
	 */
	public mutating func `write`<T>(value: T, using path: WritableKeyPath<Self, T>) async throws where T: Codable {
//		var _self = self
//		_self[keyPath: path] = value
		self[keyPath: path] = value
		do {
			try await Firappuccino.Writer.`write`(value: value, using: path, in: self)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
		}
	}
	
	/**
	 Increments a specific field in an FDocument.
	 
	 - parameter path: The path to the field to update.
	 - parameter increment: The amount to increment by.
	 */
	public mutating func increment<T>(_ path: WritableKeyPath<Self, T>, by increment: T) async throws where T: AdditiveArithmetic {
		do {
			var fieldValue = self[keyPath: path]
			if let incrementAmount = increment as? Int {
				try await Firappuccino.Counter.increment(path.string, by: incrementAmount, in: self)
				fieldValue.add(increment)
				self[keyPath: path] = fieldValue
//				var _self = self
//				_self[keyPath: path] = fieldValue
			}
		}
		catch let error as NSError {
			Firappuccino.logger.error("You can't increment mismatching values!")
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	/**
	 Asynchronously fetch the most up-to-date document field value from a specified keyPath.
	 
	 - parameter path: The keyPath to the field.
	 */
	public func `fetch`<T>(_ path: KeyPath<Self, T>) async throws -> T? where T: Codable {
		guard let document = try await Firappuccino.Fetcher.`fetch`(id: self.id, ofType: Self.self) else { return nil }
		return document[keyPath: path]
		
	}
	
	
	/// Assigns the specified "child" `FDocument`'s ID to a collection of DocumentIDs in a "parent" `FDocument` document in Firestore.
	/// - Parameters:
	///   - path: The path to the `field` of `DocumentID`s in the parent `FDocument`.
	///   - parent: The parent `FDocument` containing the field of `DocumentID`s
	///
	///   - remark: If `draftPosts` is a property of a `FUser` object  instance, calling
	///   ``post.relate(to: \.draftPosts, in: user)``
	///   will add the `post`'s ID to `users`'s `draftPosts`.
	///  - important: Fields will not be updated locally using this method.
	
	public func `relate`<T>(using path: WritableKeyPath<T, [DocumentID]>, in parent: T) async throws where T: FDocument {
		
		do {
			try await Firappuccino.Relator.`relate`(self, using: path, in: parent)
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

	public func writeAndRelate<T>(using path: WritableKeyPath<T, [DocumentID]>, in parent: T) async throws where T: FDocument {
		do {
			try await Firappuccino.Writer.writeAndLink(self, using: path, in: parent)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
	
	/// Unassigns the document's ID from a related list of IDs in another document.
	/// - Parameters:
	///   - path: path description
	///   - parent: parent description

	public func unlink<T>(using path: WritableKeyPath<T, [DocumentID]>, in parent: T) async throws where T: FDocument {
		do {
			try await Firappuccino.Relator.`unrelate`(self, using: path, in: parent)
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
}

