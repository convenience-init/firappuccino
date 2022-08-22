import Foundation


public extension UUID {
	var uuidStringSansDashes: String {
		get {
			return self.uuidString.replacingOccurrences(of: "-", with: "")
		}
	}
}
