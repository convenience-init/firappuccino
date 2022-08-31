import SwiftUI


struct ExamplePostRow: View {
	@State var postService: ExamplePostService
	
	var body: some View {
		ZStack {
			HStack(alignment: .top, spacing: 16) {
				profilePicture
				VStack(alignment: .leading, spacing: 2) {
					
					Text(postService.examplePost.title)
						.font(.title2.weight(.bold))
						.lineLimit(1)
						.foregroundColor(.white)
					
					Text(postService.examplePost.message)
						.font(.subheadline.weight(.bold))
						.lineLimit(3)
						.foregroundColor(.white)
					
					Text("submitted by: \(postService.examplePost.submittingUserDisplayName)")
						.font(.footnote)
						.foregroundColor(.white)
						.opacity(0.7)
					
					Text("\(postService.examplePost.likes) Likes")
						.font(.caption2.weight(.bold))
						.lineLimit(1)
						.foregroundColor(.white)
				}
				Spacer()
			}
			.frame(minWidth: 282)
			.blurBackground(color: .clear)
			.background(RadialGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.9921568627, green: 0.2470588235, blue: 0.2, alpha: 0.8043253311)).opacity(0.8), Color(#colorLiteral(red: 0.2980392157, green: 0, blue: 0.7843137255, alpha: 0.597785596)).opacity(0.2)]), center: .bottomTrailing, startRadius: 5, endRadius: 900))
			.overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white).blendMode(.overlay))
			.aspectRatio(contentMode: .fit)
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
		}
	}
	
	var profilePicture: some View {
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

//struct ExamplePostRow_Previews: PreviewProvider {
//	static var previews: some View {
//		ExamplePostRow(examplePost: ExamplePost())
//	}
//}
