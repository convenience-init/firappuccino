import UIKit

class LegacyPushNotificationSender {
	func sendPushNotification(to token: String, title: String, body: String) {
		let urlString = "https://fcm.googleapis.com/fcm/send"
		let url = NSURL(string: urlString)!
		let paramString: [String : Any] = [
			"to": token,
			"notification": [
				"title": title, "body": body
			],
			"data": ["count": 0]
		]
		
		let request = NSMutableURLRequest(url: url as URL)
		request.httpMethod = "POST"
		request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("key=AAAAAlm70VY:APA91bHReDsmGJIIO2eP1s7ss10mjOzhDGUb0fVIEENPW3s0twlrhhJ64mGSgwnqvLkHGk7BkJkLa9B1_IT6nsUBO58VjvbYTMQtvgrKOHvylFOqbigHOZjbRt2LNbUfoS1zvE1Zv6t4", forHTTPHeaderField: "Authorization")
		
		let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
			do {
				if let jsonData = data {
					if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
						NSLog("Received data:\n\(jsonDataDict))")
					}
				}
			}
			catch let error as NSError {
				Firappuccino.logger.error("\(error.localizedDescription)")
			}
		}
		task.resume()
	}
}
