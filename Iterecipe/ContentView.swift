import SwiftUI
import HandyOperators

struct ContentView: View {
	@Binding var recipe: Recipe
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 32) {
					VStack(alignment: .leading, spacing: 0) {
						TextField("Title", text: $recipe.title, axis: .vertical)
							.font(.largeTitle.bold())
							.minimumScaleFactor(0.5)
							.foregroundStyle(.accent)
							.frame(maxWidth: .infinity, alignment: .leading)
						
						HStack {
							TextField("Source", text: $recipe.source)
								.font(.footnote)
								.foregroundStyle(.secondary)
							
							if let url = sourceLink() {
								Link(destination: url) {
									Image(systemName: "link")
								}
							}
						}
					}
					
					RevisionView(revision: $recipe.revisions[0]) // TODO
					
					notes
				}
				.padding()
				.textFieldStyle(.plain)
			}
			.scrollDismissesKeyboard(.interactively)
			.background(Color.recipeBackground)
			//.textFieldsWithoutFocusRing()
			.background( // cheeky keyboard shortcuts lol
				Group {
					Button("Done", action: unfocusTextField).keyboardShortcut(.escape, modifiers: [])
					Button("Done", action: unfocusTextField).keyboardShortcut(.return, modifiers: .command)
				}
					.opacity(0)
			)
		}
	}
	
	func sourceLink() -> URL? {
		let string = recipe.source
		guard !string.isEmpty else { return nil }
		let withScheme = string.hasPrefix("http") ? string : "https://\(string)"
		guard let url = URL(string: withScheme) else { return nil }
		guard url.host()?.contains(/\w.\w/) == true else { return nil }
		return url
	}
	
	private var notes: some View {
		RecipeSection("Notes", systemImage: "note") {
			ForEach($recipe.notes) { $note in
				GroupBox {
					Text(note.dateCreated, format: .dateTime)
						.font(.footnote)
						.foregroundStyle(.secondary)
						.frame(maxWidth: .infinity, alignment: .trailing)
					TextField("Note", text: $note.contents, axis: .vertical)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			}
			
			Button {
				recipe.notes.append(.init())
			} label: {
				Label("Add Note", systemImage: "plus")
			}
		}
	}
}

struct RevisionView: View {
	@Binding var revision: Recipe.Revision
	@Environment(\.hasRegularWidth) var hasRegularWidth
	
	var body: some View {
		if hasRegularWidth {
			HStack(alignment: .top, spacing: 16) {
				ingredients
				
				Divider()
				
				process
			}
		} else {
			ingredients
			
			process
		}
	}
	
	private var ingredients: some View {
		RecipeSection("Ingredients", systemImage: "carrot") {
			ForEach($revision.ingredients) { $ingredient in
				TextField("Item", text: $ingredient.item, axis: .vertical)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			
			Button {
				revision.ingredients.append(.init())
			} label: {
				Label("Add Ingredient", systemImage: "plus")
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
	
	private var process: some View {
		RecipeSection("Process", systemImage: "list.number") {
			ForEach($revision.steps) { $step in
				TextField("Step Description", text: $step.description, axis: .vertical)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			
			Button {
				revision.steps.append(.init())
			} label: {
				Label("Add Step", systemImage: "plus")
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}

private struct RecipeSection<Content: View>: View {
	var heading: LocalizedStringKey
	var icon: Image
	var content: Content
	
	init(_ heading: LocalizedStringKey, systemImage: String, @ViewBuilder content: () -> Content) {
		self.heading = heading
		self.icon = Image(systemName: systemImage)
		self.content = content()
	}
	
	var body: some View {
		VStack(spacing: 8) {
			Label {
				Text(heading)
			} icon: {
				icon.foregroundStyle(.accent)
			}
			.font(.title2.weight(.semibold))
			.frame(maxWidth: .infinity, alignment: .leading)
			
			Divider()
			
			content
		}
	}
}

#Preview {
	PreviewWrapper(recipe: .example)
}

#Preview {
	PreviewWrapper(recipe: .init())
}

private struct PreviewWrapper: View {
	@State var recipe: Recipe
	
	var body: some View {
		ContentView(recipe: $recipe)
	}
}
