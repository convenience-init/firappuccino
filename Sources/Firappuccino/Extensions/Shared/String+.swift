import CryptoKit
import Foundation


extension String {
	
	/// The string, reformatted for username format.
	public var inUsernameFormat: String {
		return self.replacingOccurrences(of: "[^a-zA-Z0-9_.]", with: "_", options: .regularExpression, range: nil).lowercased()
	}
	
	/// The string, reformatted for queryable format.
	public var inQueryableFormat: String {
		return self.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression, range: nil).lowercased()
	}
	
	
	/// Generates a "random" `String` of a specified character length
	/// - Parameter length: the number of characters in the returned `String`
	/// - Returns: A `String` with `length` number of random characters
	internal static func random(length: Int) -> String {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		return String((0..<length).map{ _ in letters.randomElement()! })
	}
	
	/**
	 Increments the string to the next possible string.
	 
	 - parameter name: An optional string to increment
	 - returns: The incremented string
	 */
	public func incremented(_ name: String? = nil) -> String {
		var previousName: String = name ?? self
		if let lastScalar = previousName.unicodeScalars.last {
			let lastChar = previousName.remove(at: previousName.index(before: previousName.endIndex))
			if lastChar == "z" {
				let newName = incremented(previousName) + "a"
				return newName
			} else {
				let incrementedChar = incrementScalarValue(lastScalar.value)
				return previousName + incrementedChar
			}
		} else {
			return "a"
		}
	}
	
	internal static func nonce(length: Int = 32) -> String {
		precondition(length > 0)
		let charset: [Character] =
		Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
		var result = ""
		var remainingLength = length
		while remainingLength > 0 {
			let randoms: [UInt8] = (0 ..< 16).map { _ in
				var random: UInt8 = 0
				let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
				if errorCode != errSecSuccess {
					fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
				}
				return random
			}
			randoms.forEach { random in
				if remainingLength == 0 {
					return
				}
				if random < charset.count {
					result.append(charset[Int(random)])
					remainingLength -= 1
				}
			}
		}
		return result
	}
	
	internal func sha256() -> String {
		let str = self
		let inputData = Data(str.utf8)
		let hashedData = SHA256.hash(data: inputData)
		let hashString = hashedData.compactMap {
			return String(format: "%02x", $0)
		}.joined()
		
		return hashString
	}
	
	///see also: - https://developer.apple.com/forums/thread/122005
	// try! NSRegularExpression(pattern: #"\S*@\S*\s"#, options: []).stringByReplacingMatches(in: "1.2", withTemplate: #"$1"#))
	
	/// Extracts the email prefix from a valid email address
	/// - Returns: The email address prefix, i.e. if passed `test@test.com`, "test" is returned
	internal func getEmailPrefix() throws -> String {
		do {
			return try NSRegularExpression(pattern: #"\S*@\S*\s"#, options: []).stringByReplacingMatches(in: self, withTemplate: "")
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			return self
		}
	}
	
	/// Increments a scalar value
	/// - Parameter scalarValue: The value to increment
	/// - Returns: `String` representation of the final value
	private func incrementScalarValue(_ scalarValue: UInt32) -> String {
		return String(Character(UnicodeScalar(scalarValue + 1)!))
	}
}

