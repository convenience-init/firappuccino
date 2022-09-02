import Foundation

extension Bundle {
	
	internal static var versionString: String {
		Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? " "
	}
	
	internal static var buildString: String {
		Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? " "
	}
}
