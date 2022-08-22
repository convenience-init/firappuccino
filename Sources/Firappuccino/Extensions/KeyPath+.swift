import Foundation

extension KeyPath {
	
	internal var string: String {
		NSExpression(forKeyPath: self).keyPath
	}
}
