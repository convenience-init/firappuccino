import SwiftUI


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
