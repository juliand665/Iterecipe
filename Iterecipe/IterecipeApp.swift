import SwiftUI

@main
struct IterecipeApp: App {
	var body: some Scene {
		DocumentGroup(newDocument: IterecipeDocument(recipe: .example)) { file in
			ContentView(recipe: file.$document.recipe)
				.accentColor(Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)))
		}
	}
}
