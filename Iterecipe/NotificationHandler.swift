import Foundation
import UserNotifications

final class NotificationHandler {
	private static let instance = NotificationHandler()
	
	static func configure() {
		UNUserNotificationCenter.current().delegate = instance.delegate
	}
	
	private let delegate = Delegate()
	
	private init() {}
	
	// can't hide init for an NSObject
	private final class Delegate: NSObject, UNUserNotificationCenterDelegate {
		func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
#if os(macOS) // unfortunately can't find a way to do this on iOS; UIApplication.shared.open doesn't work for files as of iOS 17.0
			let content = response.notification.request.content
			guard let recipeURL = content.userInfo["recipeURL"] as? String else {
				print("missing file url in received notification:", content)
				return
			}
			guard let url = URL(string: recipeURL) else {
				print("invalid url in received notification:", recipeURL)
				return
			}
			
			Task { @MainActor in
				let result = NSWorkspace.shared.open(url)
				print("open result for \(url):", result)
			}
#endif
		}
		
		func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
			.banner // it would simply not display otherwise
		}
	}
}
