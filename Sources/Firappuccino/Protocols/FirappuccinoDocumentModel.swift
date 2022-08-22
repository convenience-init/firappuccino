
/**
 A protocol that requires `Codable` conformance and provides a way of parsing of `DocumentID`'s stored in another document into their appropriate `Type` models.
 */
public protocol FirappuccinoDocumentModel: Codable {}

public extension FirappuccinoDocumentModel {
	
	/// A string representing the model's type.
	var typeName: CollectionName {
		return Firappuccino.colName(of: Self.self)
	}
}
