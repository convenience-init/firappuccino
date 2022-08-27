import SwiftUI
import Firappuccino

struct AuthView: View {
	@EnvironmentObject var authService: ExampleAuthService
	@State var authType = AuthenticationType.login

	var body: some View {
		ZStack {
				VStack(spacing: 32) {
					Spacer()
					
					if (!authService.isAuthenticating) {
						AuthForm(authType: $authType)
					}
					else {
						ProgressView()
					}
					
					SignInAppleButton {
						
						Task { try authService.login(with: .signInWithApple)
						}
					}
					.frame(width: 130, height: 44)
					Spacer()
				}
		}

	}
}

struct AuthView_Previews: PreviewProvider {
	static var previews: some View {
		AuthView()
	}
}
