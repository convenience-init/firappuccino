import SwiftUI
import Firappuccino

struct ExamplePostsView: View {
	@EnvironmentObject var postsService: ExamplePostsService
	@EnvironmentObject var authService: ExampleAuthService
	@State var showingAlert = false
	@State var text = ""
	@State var messageText = ""
	
	var body: some View {
		ZStack(alignment: .top) {
			VStack {
				HStack {
				}
				ExamplePostsRandomAccessListView(postServices: postsService.postServices)

				TextFieldAlertView(
					text: $text,
					messageText: $messageText,
					isShowingAlert: $showingAlert,
					placeholder: "Add Post Title",
					placeholder2: "Add Post Message",
					title: NSLocalizedString("AddTitle", comment: ""),
					message: NSLocalizedString("AddTitleDesc", comment: ""),
					leftButtonTitle: NSLocalizedString("Cancel", comment: ""),
					rightButtonTitle: NSLocalizedString("Add", comment: ""),
					leftButtonAction: {
						text = ""
						messageText = ""
					},
					rightButtonAction: {
						Task {
							try await postsService.addPost(ExamplePost(userId: authService.currentUser.id, submittingUserDisplayName: authService.currentUser.displayName, title: text, message: messageText))
							text = ""
							messageText = ""
						}
					}
				)
				.frame(width: 0, height: 0)
			}
			.background(Image("login").resizable())
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.floatingActionButton(color: Color.teal, image: Image(systemName: "plus").foregroundColor(.white)) {
				showingAlert.toggle()
			}
			.navigationBarHidden(true)
		}
	}
}

//struct ExamplePostsView_Previews: PreviewProvider {
//	static var previews: some View {
//		ExamplePostsView().environmentObject(ExamplePostsService())
//	}
//}
