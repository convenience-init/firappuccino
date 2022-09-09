
/**
 A protocol that requires `Codable` conformance and provides a way of parsing of `DocumentID`'s stored in another document into their appropriate `Type` models.
 */
public protocol FModel: Codable {}

public extension FModel {
	
	/// A string representing the model's type.
	var typeName: CollectionName {
		return Firappuccino.colName(of: Self.self)
	}
}
