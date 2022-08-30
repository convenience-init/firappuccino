import Foundation

extension KeyPath {
	
	 var string: String {
		NSExpression(forKeyPath: self).keyPath
	}
}
