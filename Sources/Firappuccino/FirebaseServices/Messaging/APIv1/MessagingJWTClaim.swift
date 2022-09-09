import SwiftJWT

/// The Custom ``SwiftJWT.Claims`` Object to Create the signed `JWT` to send for a `Bearer` token.
struct MessagingJWTClaim: Claims {
	let iss: String
	let scope: String
	let aud: String
	let exp: Date?
	let iat: Date?
}
