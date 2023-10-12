import SwiftUI

@main
struct IterecipeApp: App {
	var body: some Scene {
		DocumentGroup(newDocument: IterecipeDocument(recipe: .init())) { file in
			ContentView(recipe: file.$document.recipe)
		}
	}
}
