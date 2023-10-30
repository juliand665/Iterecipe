import Foundation
import Observation
import UserDefault
import HandyOperators

@Observable
@MainActor
final class ProcessManager {
	@UserDefault("ProcessManager.stored")
	private static var storedProcesses: [Process.StoredData] = []
	
	private var activeProcesses: [URL: Process] = .init(
		uniqueKeysWithValues: ProcessManager.storedProcesses.lazy.map { ($0.recipeURL, .init($0)) }
	)
	
	init() {
		keepUpdated(throttlingBy: .seconds(1)) { [weak self] in
			guard let self else { return }
			Self.storedProcesses = self.activeProcesses.values.map { $0.data() }
		}
	}
	
	func process(forRecipeAt url: URL) -> Process? {
		activeProcesses[url]
	}
	
	func startProcess(forRecipeAt url: URL) {
		activeProcesses[url] = .init(recipeURL: url)
	}
	
	func endProcess(forRecipeAt url: URL) {
		let removed = activeProcesses.removeValue(forKey: url)
		assert(removed != nil)
	}
}

@Observable
@MainActor
final class Process: Identifiable {
	let id: ObjectID<Process>
	var recipeURL: URL
	var checklist = Checklist()
	
	init(recipeURL: URL) {
		self.id = .init()
		self.recipeURL = recipeURL
	}
	
	fileprivate init(_ data: StoredData) {
		self.id = data.id
		self.recipeURL = data.recipeURL
		self.checklist = data.checklist
	}
	
	fileprivate func data() -> StoredData {
		.init(id: id, recipeURL: recipeURL, checklist: checklist)
	}
	
	fileprivate struct StoredData: Codable, DefaultsValueConvertible {
		let id: Process.ID
		var recipeURL: URL
		var checklist = Checklist()
	}
}

struct Checklist: Codable {
	var completedIngredients: Set<TextItem.ID> = []
	var completedSteps: Set<TextItem.ID> = []
}
