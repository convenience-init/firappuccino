import SwiftUI

extension View {
	func initializeAlert(_ alertManager: AppAlertView) -> some View {
		self.modifier(AlertViewModifier(alert: alertManager))
	}
	
	func initializeAlertActionSheet(_ alertManager: AppAlertView) -> some View {
		self.modifier(ActionSheetModifier(alert: alertManager))
	}
	
	func angularGradientGlow(colors: [Color]) -> some View {
		self.overlay(AngularGradient(gradient: Gradient(colors: colors), center: .center, angle: Angle(degrees: 0)))
			.mask(self)
	}
	
	func linearGradientBackground(colors: [Color]) -> some View {
		self.overlay(LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing))
			.mask(self)
	}
	
	func blurBackground(color: Color, padding: CGFloat = 16) -> some View {
		self.padding(padding)
			.background(color)
			.background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
			.overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white, lineWidth: 1))
			.mask(RoundedRectangle(cornerRadius: 20, style: .continuous))
		
	}
	
	@ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
		if condition {
			transform(self)
		} else {
			self
		}
	}
}
