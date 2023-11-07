import Foundation
import UserNotifications
import UserDefault
import HandyOperators

@Observable
@MainActor
final class ProcessManager {
	@UserDefault("ProcessManager.stored")
	private static var storedProcesses: [Process.StoredData] = []
	
	private var activeProcesses: [URL?: Process] = .init(
		uniqueKeysWithValues: ProcessManager.storedProcesses.lazy.map { ($0.recipeURL, .init($0)) }
	)
	
	init() {
		keepUpdated(throttlingBy: .seconds(1)) { [weak self] in
			guard let self else { return }
			Self.storedProcesses = self.activeProcesses.values.map { $0.data() }
		}
	}
	
	func process(forRecipeAt url: URL?) -> Process? {
		activeProcesses[url]
	}
	
	func startProcess(forRecipeAt url: URL?) {
		activeProcesses[url] = .init(recipeURL: url)
	}
	
	func endProcess(forRecipeAt url: URL?) {
		let removed = activeProcesses.removeValue(forKey: url)
		assert(removed != nil)
	}
}

@Observable
@MainActor
final class Process: Identifiable {
	let id: ObjectID<Process>
	var recipeURL: URL?
	var checklist = Checklist()
	private var reminder: Reminder?
	
	/// only non-nil if a reminder is set and still in the future
	var futureReminder: Reminder? {
		guard let reminder, reminder.target > .now else { return nil }
		return reminder
	}
	
	init(recipeURL: URL?) {
		self.id = .init()
		self.recipeURL = recipeURL
	}
	
	func scheduleReminder(withDelay delay: TimeInterval, title: String) async throws {
		clearReminder()
		
		try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
		
		let content = UNMutableNotificationContent() <- {
			$0.title = title
			$0.body = "Take a moment to note down your results and perhaps adjust the recipe for next time."
			$0.userInfo["recipeURL"] = recipeURL?.absoluteString
		}
		
		let reminder = Reminder(id: .init(), target: .now + delay)
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
		let request = UNNotificationRequest(identifier: reminder.stringID, content: content, trigger: trigger)
		try await notificationCenter.add(request)
		self.reminder = reminder
	}
	
	func clearReminder() {
		guard let reminder else { return }
		self.reminder = nil
		notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.stringID])
		notificationCenter.removeDeliveredNotifications(withIdentifiers: [reminder.stringID])
	}
	
	/// clears the reminder if it's in the past, removing any leftover notifications
	func clearPastReminder() {
		guard let reminder, reminder.target < .now else { return }
		clearReminder()
	}
	
	fileprivate init(_ data: StoredData) {
		self.id = data.id
		self.recipeURL = data.recipeURL
		self.checklist = data.checklist
		self.reminder = data.reminder
	}
	
	fileprivate func data() -> StoredData {
		.init(id: id, recipeURL: recipeURL, checklist: checklist, reminder: reminder)
	}
	
	// can't implement Codable with @MainActor isolation
	fileprivate struct StoredData: Codable, DefaultsValueConvertible {
		let id: Process.ID
		var recipeURL: URL?
		var checklist = Checklist()
		var reminder: Reminder?
	}
	
	struct Reminder: Codable {
		let id: ObjectID<Self>
		let target: Date
		
		var stringID: String {
			id.rawValue.uuidString
		}
	}
}

struct Checklist: Codable {
	var completedIngredients: Set<TextItem.ID> = []
	var completedSteps: Set<TextItem.ID> = []
}

// otherwise it's literally not possible to call some methods
extension UNNotificationRequest: @unchecked Sendable {}

private let notificationCenter = UNUserNotificationCenter.current()
