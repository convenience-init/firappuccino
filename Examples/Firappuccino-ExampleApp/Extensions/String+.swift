import Foundation

extension String {
	func trimmingLeadingAndTrailingSpaces(using characterSet: CharacterSet = .whitespacesAndNewlines) -> String {
		return trimmingCharacters(in: characterSet)
	}
	
	func sentenceCase() -> String {
		let lowercasedString = self.lowercased()
		return lowercasedString.prefix(1).uppercased() + lowercasedString.dropFirst()
	}
}
