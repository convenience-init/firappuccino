infix operator <=
infix operator -=

extension Array where Element: Equatable {
	
	internal static func <= (lhs: inout Self, rhs: Element) {
		if !lhs.contains(rhs) {
			lhs.append(rhs)
		}
	}
	
	internal static func <= (lhs: inout Self, rhs: [Element]) {
		for item in rhs {
			lhs <= item
		}
	}
	
	internal static func -= (lhs: inout Self, rhs: Element) {
		lhs -= [rhs]
	}
	
	internal static func -= (lhs: inout Self, rhs: [Element]) {
		lhs.removeAll{ rhs.contains($0) }
	}
	
	internal func chunk(size: Int) -> [Self] {
		var arr = self
		var chunks = [Self]()
		while arr.count > 0 {
			var chunk: Self = []
			while arr.count > 0 && chunk.count < 10 {
				chunk.append(arr[0])
				arr.remove(at: 0)
			}
			chunks.append(chunk)
		}
		if chunks.count == 0 {
			chunks = [[]]
		}
		return chunks
	}
}
