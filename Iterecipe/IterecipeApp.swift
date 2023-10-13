import SwiftUI

@main
struct IterecipeApp: App {
	var body: some Scene {
		DocumentGroup(newDocument: IterecipeDocument(recipe: .init())) { file in
			let filename = file.fileURL?.lastPathComponent
			let basename = filename.map { $0.replacing(/.iterecipe$/, with: "") }
			
			ContentView(recipe: file.$document.recipe)
				.navigationTitle(basename ?? "")
		}
	}
}
