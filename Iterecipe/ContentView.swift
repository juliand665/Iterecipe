import SwiftUI
//import SwiftUIMissingPieces
//import Introspect
import HandyOperators
import AlignedLabels
import ArrayBuilder

private extension Font {
	static let recipeTitle = Font.system(.largeTitle)
		.weight(.bold)
	
	static let sectionHeading = Font.system(.title2)
		.weight(.semibold)
}

private extension View {
	func textFieldsWithoutFocusRing() -> some View {
#if os(macOS)
		return introspectTextField { $0.focusRingType = .none }
#else
		return self
#endif
	}
}

private func unfocusTextField() {
	DispatchQueue.main.async {
#if os(macOS)
		NSApp.keyWindow?.makeFirstResponder(nil)
#else
		UIApplication.shared.sendAction(
			#selector(UIResponder.resignFirstResponder),
			to: nil, from: nil, for: nil
		)
#endif
	}
}

private extension Color {
#if os(macOS)
	static let recipeBackground = Self(.textBackgroundColor)
#else
	static let recipeBackground = Self(.systemBackground)
#endif
}

extension EnvironmentValues {
	var hasRegularWidth: Bool {
#if os(macOS)
		return true
#else
		return horizontalSizeClass == .regular
#endif
	}
}

struct ContentView: View {
	@Binding var recipe: Recipe
	@Environment(\.hasRegularWidth) var hasRegularWidth
	
	var body: some View {
		ScrollView {
			VStack(spacing: 32) {
				VStack(alignment: .leading, spacing: 0) {
					TextField("Title", text: $recipe.title)
						.font(.recipeTitle)
						.minimumScaleFactor(0.5)
						.foregroundStyle(.accent)
						.frame(maxWidth: .infinity, alignment: .leading)
					
					HStack {
						TextField("Source", text: $recipe.source)
							.font(.footnote)
							.foregroundStyle(.secondary)
						
						if let url = URL(string: recipe.source) {
							Link(destination: url) {
								Image(systemName: "link")
							}
						}
					}
				}
				
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
				Button("Done", action: unfocusTextField)
					.keyboardShortcut(.escape, modifiers: [])
				Button("Done", action: unfocusTextField)
					.keyboardShortcut(.return, modifiers: .command)
			}
				.opacity(0)
		)
	}
	
	@ViewBuilder
	private func section(_ heading: String, systemImage: String, @ViewBuilder content: () -> some View) -> some View {
		VStack(spacing: 8) {
			Label {
				Text(heading)
			} icon: {
				Image(systemName: systemImage)
					.foregroundStyle(.accent)
			}
			.font(.sectionHeading)
			.frame(maxWidth: .infinity, alignment: .leading)
			
			Divider()
			
			content()
		}
	}
	
	private var ingredients: some View {
		section("Ingredients", systemImage: "carrot") {
			ForEach($recipe.ingredients) { $ingredient in
				TextField("Item", text: $ingredient.item, axis: .vertical)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			
			Button {
				recipe.ingredients.append(.init())
			} label: {
				Label("Add Ingredient", systemImage: "plus")
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
	
	private var process: some View {
		section("Process", systemImage: "list.number") {
			ForEach($recipe.steps) { $step in
				TextField("Step Description", text: $step.description, axis: .vertical)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			
			Button {
				recipe.steps.append(.init())
			} label: {
				Label("Add Step", systemImage: "plus")
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
	
	private var notes: some View {
		section("Notes", systemImage: "note") {
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
