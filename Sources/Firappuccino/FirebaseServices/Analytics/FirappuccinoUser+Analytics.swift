
public extension FirappuccinoUser {
	
	/// The analytics User Properties for a `FirappuccinoUser` object.
	/// - Returns: A `Dictionary` containing data to send to ``Firebase Analytics`` when a `FirappuccinoUser` opens the application.
	/// - Note: When creating your own objects by subclassing `FirappBaseUser` convenience class or by the adopting the `FirappuccinoUserProtocol` directly, this property can be overridden to specify custom User properties to include in ``Firebase Analytics``. These `FirappuccinoUserProtocol` properties are automatically updated each time your app is opened.
	func analyticsProperties() -> [String: String] {
		return ["progress": "\(progress)", "app_version": appVersion]
	}
	
	/// Sends the `FirappuccinoUser` object's analytics properties to Firebase Analytics.
	func updateAnalyticsUserProperties() async {
		for key in analyticsProperties().keys {
			FirappuccinoAnalytics.set(String(key), value: analyticsProperties()[key])
		}
	}
}
