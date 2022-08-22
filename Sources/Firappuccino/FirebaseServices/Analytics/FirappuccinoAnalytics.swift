import FirebaseAnalytics
import FirebaseAnalyticsSwift


public typealias FirappuccinoAnalyticsEventKey = String
public typealias FirappuccinoAnalyticsUserPropertyKey = String

/**
 `FirappuccinoAnalytics` allows you to easily manage and perform the functions of Firebase Analytics.
 
 `FirappuccinoAnalytics` is divided into `Event` and `User` catagories
 
 To log an event, you can use `FirappuccinoAnalytics`' static methods:
 
 ```
 FirappuccinoAnalytics.log("post", data: [
 "title": "PostOne",
 "isDraft": true
 ])
 ```
 
 If you have a model that conforms to `FirappuccinoAnalyticsLoggable`, you can log events using the model itself:
 
 ```
 let tequila = Liquor(name: "Cuervo", proof: 181)
 FirappuccinoAnalytics.log("liquor_consumed", model: tequila)
 ```
 
 Alternatively, you can call the instance method on the loggable model:
 
 ```
 beer.log(key: "food_eaten")
 ```
 
 User Properties are automatically updated when a local `FirappuccinoUser` instance is initialized. For more information, see the documentation for ``FirappuccinoUser``'s `analyticsProperties()` method.
 
 - Remark:  No data collected by `FirappuccinoAnalytics` is linked to a specific user, and no user data are intentionally collected. If you wish to link analytics data to a specific user, call `FirappuccinoAnalytics.setUserId(_:)` first.
 */
public struct FirappuccinoAnalytics {
		
	/// The timeout duration.
	///
	/// To prevent logging spam, the timeout duration is checked. If another Analytics-related action is performed within the timeout duration, it will not be logged to Firebase Analytics.
	public static var timeout: TimeInterval = TimeInterval(2.0)
	
	/// Whether to collect analytics data.
	public static var collectAnalytics: Bool = true { didSet {
		Analytics.setAnalyticsCollectionEnabled(collectAnalytics)
	}}
		
	/// The last time data was logged to Analytics.
	public internal(set) static var lastLog: Date?
		
	/**
	 Logs an analytics event.
	 
	 - parameter key: The key of the event
	 - parameter model: The model to log.
	 */
	public static func log<T>(_ key: FirappuccinoAnalyticsEventKey, model: T) where T: FirappuccinoAnalyticsLoggable {
		log(key, data: model.analyticsData)
	}
	
	/**
	 Logs an analytics event.
	 
	 - parameter key: The key of the event
	 - parameter data: Any data associated with the event
	 */
	public static func log(_ key: FirappuccinoAnalyticsEventKey, data: [String: Any]? = [:]) {
		if let lastLog = lastLog {
			guard lastLog.distance(to: Date()) > timeout else { return }
		}
		lastLog = Date()
		Analytics.logEvent(key, parameters: data)
	}
		
	internal static func set(_ key: FirappuccinoAnalyticsUserPropertyKey, value: String?) {
		Analytics.setUserProperty(value, forName: key)
	}
}
