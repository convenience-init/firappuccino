
public extension FUser {
	
	/// The analytics User Properties for a `FUser` object.
	/// - Returns: A `Dictionary` containing data to send to ``Firebase Analytics`` when a `FUser` opens the application.
	/// - Note: When creating your own objects by subclassing `FBaseUser` convenience class or by the adopting the `FUser` directly, this property can be overridden to specify custom User properties to include in ``Firebase Analytics``. These `FUser` properties are automatically updated each time your app is opened.
	func analyticsProperties() -> [String: String] {
		return ["progress": "\(progress)", "app_version": appVersion]
	}
	
	/// Sends the `FUser` object's analytics properties to Firebase Analytics.
	func updateAnalyticsUserProperties() async {
		for key in analyticsProperties().keys {
			FAnalytics.`write`(String(key), value: analyticsProperties()[key])
		}
	}
}
