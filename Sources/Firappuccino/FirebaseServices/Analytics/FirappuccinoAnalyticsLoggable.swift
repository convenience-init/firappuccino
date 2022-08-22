
/**
 A protocol for logging custom `FirappuccinoAnalytics` events into Firebase Analytics.
 
 Some models, upon creation, can be logged to Analytics to monitor properties of user engagement. For instace, if we have a `DumbNFT` model:
 
 ```
 struct DumbNFT: FirappuccinoDocumentModel, FirappuccinoAnalyticsLoggable {
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
 
 Calling ``log(key:)`` on an instance of `DumbNFT` will log an Analytics Event to firestore with the data as provided above.
 */
public protocol FirappuccinoAnalyticsLoggable {
	
	/// The Data provided for analytics.
	var analyticsData: [String: Any] { get }
}

public extension FirappuccinoAnalyticsLoggable {
		
	/**
	 Logs an analytics event using the model.
	 
	 - parameter key: The key of the event
	 */
	func log(key: FirappuccinoAnalyticsEventKey) {
		FirappuccinoAnalytics.log(key, model: self)
	}
}
