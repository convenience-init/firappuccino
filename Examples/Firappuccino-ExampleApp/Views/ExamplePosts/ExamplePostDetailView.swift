import SwiftUI
import Firappuccino
import Firappuccino

struct ExamplePostDetailView: View {
	@EnvironmentObject var authService: ExampleAuthService
	@State var user = ExampleAuthService.currentSession.currentUser
	@State var postService: ExamplePostService
	
	var body: some View {
		ZStack(alignment: .top) {
			HStack(alignment: .center, spacing: 16) {
				VStack(alignment: .center, spacing: 6){
					Spacer()
					postImage
						.onAppear {
							Task {
								do {
									print("The post title is \(try await postService.examplePost.`fetch`(\.title) ?? "No Title")")
								}
								catch let error as NSError {
									Firappuccino.logger.error("\(error.localizedDescription)")
								}
							}
						}
					
					Divider()
						.padding()
					
					VStack(alignment: .leading, spacing: 6) {
						
						Text("Likes")
							.font(.title3.weight(.bold))
							.lineLimit(3)
							.foregroundColor(.appCard)
						Text(String(postService.examplePost.likes))
							.font(.headline.weight(.bold))
							.lineLimit(3)
							.foregroundColor(.white)
							.padding([.bottom], 12)
						
						Text("Posted by")
							.font(.title3.weight(.bold))
							.lineLimit(3)
							.foregroundColor(.appCard)
						Text(postService.examplePost.submittingUserDisplayName)
							.font(.headline.weight(.bold))
							.lineLimit(3)
							.foregroundColor(.white)
							.padding([.bottom], 12)
						
						Text("Posted at")
							.font(.title3.weight(.bold))
							.lineLimit(3)
							.foregroundColor(.appCard)
						Text(postService.examplePost.createdAt.formatted())
							.font(.headline.weight(.bold))
							.lineLimit(3)
							.foregroundColor(.white)
							.padding([.bottom], 12)
						Spacer()
					}
				}
				
				VStack(alignment: .leading, spacing: 6) {
					Spacer()
					Text("Post Title")
						.font(.title3.weight(.bold))
						.lineLimit(3)
						.foregroundColor(.appCard)
					Text(postService.examplePost.title)
						.font(.headline.weight(.bold))
						.lineLimit(3)
						.foregroundColor(.white)
						.padding([.bottom], 12)
					
					Spacer()
					
					Text("Post Message")
						.font(.title3.weight(.bold))
						.lineLimit(3)
						.foregroundColor(.appCard)
					Text(postService.examplePost.message)
						.font(.headline.weight(.bold))
						.foregroundColor(.white)
						.padding([.bottom], 12)
					Spacer()
				}
			}
			.frame(minWidth: 242 , maxWidth: 282, minHeight: 420, maxHeight: 666, alignment: .top)
			.blurBackground(color: .clear)
			.background(RadialGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.9921568627, green: 0.2470588235, blue: 0.2, alpha: 0.8043253311)).opacity(0.8), Color(#colorLiteral(red: 0.2980392157, green: 0, blue: 0.7843137255, alpha: 0.597785596)).opacity(0.2)]), center: .bottomTrailing, startRadius: 5, endRadius: 900))
			.overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white).blendMode(.overlay))
			.aspectRatio(contentMode: .fit)
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
			Spacer()
		}
		.floatingActionButton(color: .white, image: Image(systemName: postService.examplePost.likedByUserIds.contains(authService.currentUser.id) ? "heart.fill" : "heart").foregroundColor(.red)) {
			Task { try? await postService.like() }
		}
	}
	
	var postImage: some View {
		ZStack {
			Image(systemName: "circle.fill")
				.resizable()
				.font(.system(size: 66))
				.angularGradientGlow(colors: [Color(#colorLiteral(red: 0.2274509804, green: 0.4, blue: 1, alpha: 1)), Color(#colorLiteral(red: 0.2156862745, green: 1, blue: 0.6235294118, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.9176470588, blue: 0.1960784314, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.2039215686, blue: 0.2745098039, alpha: 1))])
				.frame(width: 66, height: 66)
				.blur(radius: 10)
			
			
			VStack {
				AsyncImage(url: URL(string: "https://source.unsplash.com/random/100x100/?guinea+pig"), content: { image in
					image.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 77, height: 77, alignment: .center)
						.cornerRadius(50)
				}, placeholder: {
					Image(uiImage: UIImage(imageLiteralResourceName: "laughingCat"))
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 77, height: 77, alignment: .center)
						.cornerRadius(50)
				})
			}
			.overlay(Circle().stroke(Color.white, lineWidth: 1))
		}
	}
	
}

//struct ExamplePostDetailView_Previews: PreviewProvider {
//	static var previews: some View {
//		ExamplePostDetailView(examplePost: ExamplePost())
//	}
//}
