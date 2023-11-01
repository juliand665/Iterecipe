import SwiftUI
import HandyOperators

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
			
			DocumentView(document: file.$document)
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

struct DocumentView: View {
	@Binding var document: IterecipeDocument
	
	var body: some View {
		if let error = document.loadingError {
			errorView(for: error)
		} else {
			ContentView(recipe: $document[dynamicMember: \.recipe!])
		}
	}
	
	func errorView(for error: any Error) -> some View {
		ScrollView {
			VStack(spacing: 16) {
				Text("Could not load recipe!")
					.font(.title2.bold())
				
				Text(error.localizedDescription)
					.frame(maxWidth: .infinity, alignment: .leading)
				
				Text(verbatim: "" <- { dump(error, to: &$0) })
					.font(.footnote.monospaced())
			}
			.foregroundStyle(.secondary)
			.frame(maxHeight: .infinity)
			.padding()
		}
		.scrollBounceBehavior(.basedOnSize)
	}
}
