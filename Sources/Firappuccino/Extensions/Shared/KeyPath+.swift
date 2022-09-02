import Foundation

public extension KeyPath {
	internal var fieldName: String {
		NSExpression(forKeyPath: self).keyPath
	}
}

public extension KeyPath where Root: FModel {
	internal static func fieldName(from keyPath: PartialKeyPath<Root>) -> String? {
		return String(describing: keyPath)
	}
}
