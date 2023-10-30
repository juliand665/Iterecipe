import SwiftUI

@main
struct IterecipeApp: App {
	@MainActor
	private static let processManager = ProcessManager()
	
	var body: some Scene {
		DocumentGroup(newDocument: IterecipeDocument(recipe: .init())) { file in
			let filename = file.fileURL?.lastPathComponent
			let basename = filename.map { $0.replacing(/.iterecipe$/, with: "") }
			
			ContentView(recipe: file.$document.recipe, recipeURL: file.fileURL)
				.navigationTitle(basename ?? "")
				.environment(Self.processManager)
		}
	}
}
