import SwiftUI

struct SamplePostsView: View {
	@EnvironmentObject var postsService: ExamplePostsService
	
	@State private var showingAlert = false
	@State private var text = ""
	
	var body: some View {
		VStack {
			Button(action: {
				showingAlert.toggle()
			}) {
				Text("Add").style(.actionButtonText)
			}
			
			LazyVStack {
				ForEach(postsService.postServices) { postService in
					Text(postService.examplePost.title)
				}
			}
			.onAppear {
				print($postsService.postRepository.examplePosts)
			}
			
			TextFieldAlertView(
				text: $text,
				isShowingAlert: $showingAlert,
				placeholder: "",
				title: NSLocalizedString("AddTitle", comment: ""),
				message: NSLocalizedString("AddTitleDesc", comment: ""),
				leftButtonTitle: NSLocalizedString("Cancel", comment: ""),
				rightButtonTitle: NSLocalizedString("Add", comment: ""),
				leftButtonAction: {
					text = ""
				},
				rightButtonAction: {
					Task {
						try await postsService.addPost(ExamplePost(title: text, message: "Test message"))	
					}
					text = ""
				}
			)
			.frame(width: 0, height: 0)
			
		}
	}
}

//struct SamplePostsView_Previews: PreviewProvider {
//	static var previews: some View {
//		SamplePostsView().environmentObject(ExamplePostsService())
//	}
//}
