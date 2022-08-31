import Foundation

enum AuthenticationType: String {
	case login
	case signup
	
	var text: String {
		rawValue.capitalized
	}
	
	var assetBackgroundName: String {
		self == .login ? "login" : "login"
	}
	
	var footerText: String {
		switch self {
			case .login:
				return "Not a member, signup"
				
			case .signup:
				return "Already a member? login"
		}
	}
}
