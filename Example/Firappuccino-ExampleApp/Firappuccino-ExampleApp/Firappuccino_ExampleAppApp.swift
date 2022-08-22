import SwiftUI
import Firappuccino

class AppDelegate: NSObject, UIApplicationDelegate {
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		
		FirappuccinoConfigurator.configurate(WithOptions: nil, globalOverrideLogLevel: Logger.Level.error)
		
		return true
	}
	// TODO: Add FPNMessaging
}

@main
struct Firappuccino_ExampleAppApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
	
	//TODO: Add Auth
	var body: some Scene {
		WindowGroup {
			NavigationView {
				ContentView()
			}
		}
	}
}
