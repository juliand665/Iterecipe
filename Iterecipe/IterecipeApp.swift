import SwiftUI

@main
struct IterecipeApp: App {
	@MainActor
	private static let processManager = ProcessManager()
	
	init() {
		NotificationHandler.configure() // has to happen before launch finishes
	}
	
	var body: some Scene {
		DocumentGroup(newDocument: IterecipeDocument(recipe: .init())) { file in
			let filename = file.fileURL?.lastPathComponent
			let basename = filename.map { $0.replacing(/.iterecipe$/, with: "") }
			
			ContentView(recipe: file.$document.recipe)
				.navigationTitle(basename ?? "")
				.environment(Self.processManager)
				.environment(\.recipeURL, file.fileURL)
		}
	}
}

extension EnvironmentValues {
	var recipeURL: URL? {
		get { self[RecipeURLKey.self] }
		set { self[RecipeURLKey.self] = newValue }
	}
	
	private enum RecipeURLKey: EnvironmentKey {
		static let defaultValue: URL? = nil
	}
}
