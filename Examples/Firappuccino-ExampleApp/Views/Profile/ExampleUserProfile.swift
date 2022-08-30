import SwiftUI

struct ExampleUserProfile: View {
	@EnvironmentObject var authService: ExampleAuthService
	@State var user = ExampleAuthService.currentSession.currentUser
	
	var body: some View {
		ZStack(alignment: .top) {
			VStack(alignment: .center, spacing: 16) {
				profilePicture
				Text(user.username)
					.font(.title.weight(.bold))
					.lineLimit(3)
					.foregroundColor(.white)
				
				Divider()
					.padding()
				
				VStack(alignment: .leading, spacing: 6) {
					
					Text("Email")
						.font(.title3.weight(.bold))
						.lineLimit(3)
						.foregroundColor(.white)
					Text(user.email)
						.font(.headline.weight(.bold))
						.lineLimit(3)
						.foregroundColor(.white)
						.padding([.bottom], 12)
					
					Text("Display name")
						.font(.title3.weight(.bold))
						.lineLimit(3)
						.foregroundColor(.white)
					Text(user.displayName)
						.font(.headline.weight(.bold))
						.foregroundColor(.white)
						.padding([.bottom], 12)
					
					Text("Total likes received")
						.font(.title3.weight(.bold))
						.lineLimit(3)
						.foregroundColor(.white)
					Text(String(user.totalLikesReceived))
						.font(.headline.weight(.bold))
						.lineLimit(3)
						.foregroundColor(.white)
						.padding([.bottom], 12)
					
					Text("Joined on")
						.font(.title3.weight(.bold))
						.lineLimit(3)
						.foregroundColor(.white)
					Text(user.createdAt.ISO8601Format())
						.font(.headline.weight(.bold))
						.lineLimit(3)
						.foregroundColor(.white)
						.padding([.bottom], 12)
				}
			}
			.frame(minWidth: 242 , maxWidth: 262, maxHeight: 555, alignment: .top)
			.blurBackground(color: .clear)
			.background(RadialGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.9921568627, green: 0.2470588235, blue: 0.2, alpha: 0.8043253311)).opacity(0.8), Color(#colorLiteral(red: 0.2980392157, green: 0, blue: 0.7843137255, alpha: 0.597785596)).opacity(0.2)]), center: .bottomTrailing, startRadius: 5, endRadius: 900))
			.overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white).blendMode(.overlay))
			.aspectRatio(contentMode: .fit)
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
			.navigationBarHidden(true)
			Spacer()
		}
		.floatingActionButton(color: Color.teal, image: Image(systemName: "person.crop.circle.badge.xmark").foregroundColor(.white)) {
			try? authService.signout()
		}
	}
	
	var profilePicture: some View {
		ZStack {
			Image(systemName: "circle.fill")
				.resizable()
				.font(.system(size: 66))
				.angularGradientGlow(colors: [Color(#colorLiteral(red: 0.2274509804, green: 0.4, blue: 1, alpha: 1)), Color(#colorLiteral(red: 0.2156862745, green: 1, blue: 0.6235294118, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.9176470588, blue: 0.1960784314, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.2039215686, blue: 0.2745098039, alpha: 1))])
				.frame(width: 111, height: 111)
				.blur(radius: 10)
			
			
			VStack {
				AsyncImage(url: URL(string: "https://source.unsplash.com/random/100x100/?guinea+pig"), content: { image in
					image.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 111, height: 111, alignment: .center)
						.cornerRadius(50)
				}, placeholder: {
					Image(uiImage: UIImage(imageLiteralResourceName: "laughingCat"))
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 111, height: 111, alignment: .center)
						.cornerRadius(50)
				})
			}
			.overlay(Circle().stroke(Color.white, lineWidth: 1))
		}
	}
}

//struct ExampleUserProfile_Previews: PreviewProvider {
//	static var previews: some View {
//		ExampleUserProfile()
//	}
//}
