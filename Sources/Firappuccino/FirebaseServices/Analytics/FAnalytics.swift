import FirebaseAnalytics
import FirebaseAnalyticsSwift


public typealias FAnalyticsEventKey = String
public typealias FAnalyticsUserPropertyKey = String


public protocol FAnalyticsParams {

	/// Convenience method to
	/// - Returns: A dictionary containing the `FAnalytics` data to send to Firebase
	func toModel(properties: Any ...) -> [String: Any]
}
/**
 `FAnalytics` allows you to easily manage and perform the functions of Firebase Analytics.
  
 To log an event, you can use `FAnalytics` provided static methods:
 
 ```
FAnalytics.log("post", data: [
 "title": "PostOne",
 "isDraft": true
 ])
 ```
 
 If you have a model that conforms to `FAnalyticsLoggable`, you can log events using the model itself:
 
 ```
 let tequila = Liquor(name: "Cuervo", proof: 181)
 FAnalytics.log("liquor_consumed", model: tequila)
 ```
 
 Alternatively, you can call the instance method on the loggable model:
 
 ```
 beer.log(key: "food_eaten")
 ```
 
 User Properties are automatically updated when a local `FUser` instance is initialized. For more information, see the documentation for ``FUser``'s `analyticsProperties()` method.
 
 - Remark:  No data collected by `FAnalytics` is linked to a specific user, and no user data are intentionally collected. If you wish to link analytics data to a specific user, call `FAnalytics.setUserId(_:)` first.
 */
public struct FAnalytics {

	/// The timeout duration.
	/// If another Analytics-related action is performed within the timeout duration, it will not be logged to Firebase Analytics.
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
	public static func log<T>(_ key: FAnalyticsEventKey, model: T) where T: FAnalyticsLoggable {
		log(key, data: model.analyticsData)
	}
	
	/**
	 Logs an analytics event.
	 
	 - parameter key: The key of the event
	 - parameter data: Any data associated with the event
	 */
	public static func log(_ key: FAnalyticsEventKey, data: [String: Any]? = [:]) {
#if DEBUG
		print("Don't send events...")
#else
		if let lastLog = lastLog {
			guard lastLog.distance(to: Date()) > timeout else { return }
		}
		lastLog = Date()
		Analytics.logEvent(key, parameters: data)
#endif
	}
		
	internal static func `write`(_ key: FAnalyticsUserPropertyKey, value: String?) {
		#if DEBUG
				print("Don't send events...")
		#else
		Analytics.setUserProperty(value, forName: key)
		#endif

	}
}
