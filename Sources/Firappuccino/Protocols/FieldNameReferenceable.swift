import Foundation

public protocol FieldNameReferenceable {
	static var fieldNames: [PartialKeyPath<Self>: String] { get }
}

public extension FieldNameReferenceable where Self: FModel {
	static func fieldName(from keyPath: PartialKeyPath<Self>) -> String? {
		return fieldNames[keyPath]
	}
}
