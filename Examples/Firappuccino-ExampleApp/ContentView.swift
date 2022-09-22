import SwiftUI

struct ContentView: View {
	@State private var onboarded: Bool = UserDefaults.standard.bool(forKey: ExampleAppConstants.shared.didFinishWalkThroughKey!)
	
	var body: some View {
		ZStack {
			
			if !onboarded {
				PageView([WalkThroughContainerView(page: .one), WalkThroughContainerView(page: .two)], finished: $onboarded)
					.edgesIgnoringSafeArea(.all)
			}
			else {
				MainView()
					.environmentObject(ExamplePostsService())
					.environmentObject(ExampleAuthService.currentSession)
			}
		}
		.transition(.slide)
		//		.animation(.easeInOut)
		
	}
}

//struct ContentView_Previews: PreviewProvider {
//	static var previews: some View {
//		ContentView()
//	}
//}
