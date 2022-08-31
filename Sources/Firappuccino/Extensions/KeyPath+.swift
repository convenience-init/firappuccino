import Foundation

extension WritableKeyPath {
	
	var string: String {
		NSExpression(forKeyPath: self).keyPath
	}
}

