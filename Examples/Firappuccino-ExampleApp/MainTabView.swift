import SwiftUI

struct TabItem: View {
	
	let text: String
	
	let image: String
	
	var body: some View {
		VStack {
			Image(systemName: image)
			Text(text)
		}
	}
}

enum TabName: String, CaseIterable, Codable {
	case examplePosts = "Example Posts"
	case exampleProfile = "Example Profile"
}

struct MainTabView: View {
	@EnvironmentObject var authService: ExampleAuthService
	@EnvironmentObject var postsService: ExamplePostsService
	@State var selectedTab: TabName = .examplePosts
	
	var body: some View {
		TabView(selection: $selectedTab) {
			// Example Posts
			ExamplePostsView()
				.navigationBarHidden(true)
				.environmentObject(authService)
				.environmentObject(postsService)
				.tabItem {
					TabItem(text: TabName.examplePosts.rawValue, image: "doc.richtext")
				}
				.tag(TabName.examplePosts)
			
			// Example Profile
			ExampleUserProfile()
				.navigationBarHidden(true)
				.environmentObject(authService)
				.tabItem {
					TabItem(text: TabName.exampleProfile.rawValue, image: "person.crop.circle")
				}
				.tag(TabName.exampleProfile)
		}
	}
}

//struct MainTabView_Previews: PreviewProvider {
//	static var previews: some View {
//		MainTabView()
//	}
//}
