import Foundation

extension NSRegularExpression {
	
	internal func stringByReplacingMatches(in string: String, withTemplate template: String) -> String {
		let r = NSRange.init(string.startIndex..<string.endIndex, in: string)
		return self.stringByReplacingMatches(in: string, options: [], range: r, withTemplate: template)
	}
}

