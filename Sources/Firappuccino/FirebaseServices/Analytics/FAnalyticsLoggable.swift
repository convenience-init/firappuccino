
/**
 A protocol for logging custom `FAnalytics` events into Firebase Analytics.
 
 Some models, upon creation, can be logged to Analytics to monitor properties of user engagement. For instace, if we have a `DumbNFT` model:
 
 ```swift
 struct DumbNFT: FModel, FAnalyticsLoggable {
 var name: String
 var price: Int
 var analyticsData: [String : Any] {
 [
 "name": name,
 "price": price > 650_000
 ]
 }
 }
 ```
 
 Calling ```log(key:)``` on an instance of `DumbNFT` will log an Analytics Event to firestore with the data as provided above.
 */
public protocol FAnalyticsLoggable {
	
	/// The Data provided for analytics.
	var analyticsData: [String: Any] { get }
}

public extension FAnalyticsLoggable {
		
	/**
	 Logs an analytics event using the model.
	 
	 - parameter key: The key of the event
	 */
	func log(key: FAnalyticsEventKey) {
		FAnalytics.log(key, model: self)
	}
}
