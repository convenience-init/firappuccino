import Foundation
import Firebase
import FirebaseAnalytics

// - note: Please customize this file to send `FANalytics` events to Firebase Analytics.
struct AnalyticsUtil {
	struct Params {
		//        let property1: String?
		//        let property2: String?
		
		func toObject() -> [String: Any] {
			return [:]
		}
	}
	
	enum EventType: String {
		case onboarded
		case user
		case app
	}
	
	static func logEvent(_ event: EventType, params: Params? = nil) {
		#if DEBUG
		print("Don't send events...")
		#else
		Analytics.logEvent(event.rawValue, parameters: params?.toObject() ?? [:])
		#endif
		
	}
}
