import SwiftUI

struct MainView: View {
	@EnvironmentObject var authService: ExampleAuthService
	@EnvironmentObject var postService: ExamplePostsService
	
	var body: some View {
		Group {
			if authService.user != nil {
				NavigationView {
					SamplePostsView()
				}
				.environmentObject(authService)
				.environmentObject(postService)
			}
			else {
				AuthView(authType: .login)
			}
		}
		.animation(.easeInOut)
		.transition(.move(edge: .bottom))
		.preferredColorScheme(.dark)
	}
}

struct MainView_Previews: PreviewProvider {
	static var previews: some View {
		MainView()
		.environmentObject(ExampleAuthService.currentSession)
		.environmentObject(ExamplePostsService())
	}
}
