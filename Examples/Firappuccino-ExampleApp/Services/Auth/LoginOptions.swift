import Foundation

enum LoginOption {
	case signInWithGoogle
	case signInWithApple
	case emailAndPassword(email: String, password: String)
}
