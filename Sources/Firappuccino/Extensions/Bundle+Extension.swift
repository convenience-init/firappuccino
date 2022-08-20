
extension Bundle {
	
	// MARK: - Internal Static Properties
	
	internal static var versionString: String {
		Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
	}
	
	internal static var buildString: String {
		Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
	}
}
