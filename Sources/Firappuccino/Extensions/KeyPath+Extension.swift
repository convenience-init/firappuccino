
extension KeyPath {
	
	// MARK: - Internal Properties
	
	internal var string: String {
		NSExpression(forKeyPath: self).keyPath
	}
}
