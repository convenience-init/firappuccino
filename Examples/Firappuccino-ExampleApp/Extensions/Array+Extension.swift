import Foundation

extension Array where Element: Hashable {
	func addUnique(array: Array) -> Array {
		let dict = Dictionary(map{ ($0, 1) }, uniquingKeysWith: +)
		return self + array.filter{ dict[$0] == nil }
	}
	
	subscript(index: Int, default defaultValue: @autoclosure () -> Element) -> Element {
		guard index >= 0, index < endIndex else {
			return defaultValue()
		}
		
		return self[index]
	}
}
