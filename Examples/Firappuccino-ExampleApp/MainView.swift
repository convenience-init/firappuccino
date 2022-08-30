import SwiftUI
import FirebaseAuth

struct MainView: View {
	@EnvironmentObject var authService: ExampleAuthService
	@EnvironmentObject var postsService: ExamplePostsService
	
	var body: some View {
		Group {
			if let _ = Auth.auth().currentUser {
					MainTabView()
				.environmentObject(authService)
				.environmentObject(postsService)
			}
			else {
				AuthView(authType: .login)
				.environmentObject(authService)
			}
		}
		.animation(.easeInOut)
		.transition(.move(edge: .bottom))
		.preferredColorScheme(.dark)
	}
}

//struct MainView_Previews: PreviewProvider {
//	static var previews: some View {
//		MainView()
//		.environmentObject(ExampleAuthService.currentSession)
//		.environmentObject(ExamplePostsService())
//	}
//}
