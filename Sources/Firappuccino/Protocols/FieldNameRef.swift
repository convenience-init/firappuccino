import Foundation

public protocol FieldNameRef {
	static var fieldNames: [PartialKeyPath<Self>: String] { get }
}

public extension FieldNameRef where Self: FModel {
	static func fieldName(from keyPath: PartialKeyPath<Self>) -> String? {
		return fieldNames[keyPath]
	}
}


