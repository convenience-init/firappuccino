import SwiftUI
import Foundation
import Firappuccino

struct AuthForm: View {
	@EnvironmentObject var authService: ExampleAuthService
	
	@State var email: String = ""
	@State var firstName: String = ""
	@State var lastName: String = ""
	@State var password: String = ""
	@State var passwordConf: String = ""
	@State var isShowingPassword = false
	
	@Binding var authType: AuthenticationType
	
	var body: some View {
		ZStack {
			VStack(spacing: 16) {
				TextField("Email", text: $email)
					.textContentType(.emailAddress)
					.keyboardType(.emailAddress)
					.autocapitalization(.none)
				if authType == .signup {
					TextField("First Name", text: $firstName)
						.textContentType(.givenName)
						.keyboardType(.namePhonePad)
						.autocapitalization(.words)
					
					TextField("Last Name", text: $lastName)
						.textContentType(.familyName)
						.keyboardType(.namePhonePad)
						.autocapitalization(.words)
				}
				if isShowingPassword {
					TextField("Password", text: $password)
						.textContentType(.password)
						.autocapitalization(.none)
				} else {
					SecureField("Password", text: $password)
				}
				
				if authType == .signup {
					
					if isShowingPassword {
						TextField("Password Confirmation", text: $passwordConf)
							.textContentType(.password)
							.autocapitalization(.none)
					} else {
						SecureField("Password Confirmation", text: $passwordConf)
					}
				}
				
				Toggle("Show password", isOn: $isShowingPassword)
					.foregroundColor(.white)
					.toggleStyle(CheckBoxStyle())
				
				Button(action: emailAuthenticationTapped) {
					Text(authType.text)
						.font(.callout)
				}
				.buttonStyle(XCAButtonStyle())
				.disabled(email.count == 0 && password.count == 0)
				
				Button(action: footerButtonTapped) {
					Text(authType.footerText)
						.font(.callout)
				}
				.foregroundColor(.white)
			}
			.textFieldStyle(RoundedBorderTextFieldStyle())
			.frame(width: 288)
			.alert(item: $authService.error) { error in
									Alert(title: Text("Error"), message: Text(error.localizedDescription))
					}
		}
	}
	
	private func emailAuthenticationTapped() {
		switch authType {
			case .login:
				do {
					try authService.login(with: .emailAndPassword(email: email, password: password))
				}
				catch let error as NSError {
					Firappuccino.logger.error("\(error.localizedDescription)")
				}
				
			case .signup:
				do {
					try authService.signup(email: email, firstName: firstName, lastName: lastName, password: password, passwordConfirmation: passwordConf)
				}
				catch let error as NSError {
					Firappuccino.logger.error("\(error.localizedDescription)")
				}
		}
	}
	
	private func footerButtonTapped() {
		clearFormField()
		authType = authType == .signup ? .login : .signup
	}
	
	private func clearFormField() {
		email = ""
		firstName = ""
		lastName = ""
		password = ""
		passwordConf = ""
		isShowingPassword = false
	}
}

struct AuthForm_Previews: PreviewProvider {
	static var previews: some View {
		AuthForm(authType: .constant(AuthenticationType.login))
		.environmentObject(ExampleAuthService.currentSession)
	}
}

