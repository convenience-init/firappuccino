import CryptoKit
import Foundation


extension String {
	
	/// The string, reformatted for username format.
	public var inUsernameFormat: String {
		return self.replacingOccurrences(of: "[^a-zA-Z0-9_.]", with: "_", options: .regularExpression, range: nil).lowercased()
	}
	
	internal static func random(length: Int) -> String {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		return String((0..<length).map{ _ in letters.randomElement()! })
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
	internal func getEmailPrefix() throws -> String {
		do {
			return try NSRegularExpression(pattern: #"\S*@\S*\s"#, options: []).stringByReplacingMatches(in: self, withTemplate: "")
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			return self
		}
	}
}

