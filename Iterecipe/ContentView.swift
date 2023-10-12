import SwiftUI
import HandyOperators

struct ContentView: View {
	@Binding var recipe: Recipe
	@State var revisionIndexFromEnd = 0
	@Environment(\.undoManager) private var undoManager
	
	var revisionIndex: Int {
		recipe.revisions.count - 1 - revisionIndexFromEnd
	}
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 32) {
					HStack(alignment: .lastTextBaseline) {
						VStack(alignment: .leading, spacing: 0) {
							TextField("Recipe Title", text: $recipe.title, axis: .vertical)
								.font(.title.bold())
								.minimumScaleFactor(0.5)
								.frame(maxWidth: .infinity, alignment: .leading)
							
							TextField("Source", text: $recipe.source)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
						
						if let url = sourceLink() {
							Link(destination: url) {
								Image(systemName: "link")
							}
						}
					}
					
					VStack {
						revisionSwitcher()
						Divider()
					}
					
					RevisionView(revision: $recipe.revisions[revisionIndex])
				}
				.padding()
				.textFieldStyle(.plain)
			}
			.scrollDismissesKeyboard(.interactively)
			.background(Color.canvasBackground)
			//.textFieldsWithoutFocusRing()
			.background( // cheeky keyboard shortcuts lol
				Group {
					Button("Done", action: unfocusTextField).keyboardShortcut(.escape, modifiers: [])
					Button("Done", action: unfocusTextField).keyboardShortcut(.return, modifiers: .command)
				}
					.opacity(0)
			)
			.toolbar {
				ToolbarItemGroup(placement: .primaryAction) {
					HStack {
						Button {
							undoManager!.undo()
						} label: {
							Label("Undo", systemImage: "arrow.uturn.backward.circle")
						}
						.disabled(undoManager?.canUndo != true)
						
						Button {
							undoManager!.redo()
						} label: {
							Label("Redo", systemImage: "arrow.uturn.forward.circle")
						}
						.disabled(undoManager?.canRedo != true)
					}
				}
			}
		}
	}
	
	func revisionSwitcher() -> some View {
		HStack {
			CircleButton("Previous Revision", systemImage: "chevron.left") {
				revisionIndexFromEnd += 1
			}
			.disabled(revisionIndexFromEnd >= recipe.revisions.count - 1)
			
			if revisionIndexFromEnd == 0 {
				Text("Current Revision")
					.frame(maxWidth: .infinity)
				
				CircleButton("Add New Revision", systemImage: "plus") {
					recipe.addRevision()
				}
			} else {
				Text("Revision \(revisionIndex + 1)/\(recipe.revisions.count)")
					.frame(maxWidth: .infinity)
				
				CircleButton("Next Revision", systemImage: "chevron.right") {
					revisionIndexFromEnd -= 1
				}
			}
		}
		.fontWeight(.medium)
	}
	
	func sourceLink() -> URL? {
		let string = recipe.source
		guard !string.isEmpty else { return nil }
		let withScheme = string.hasPrefix("http") ? string : "https://\(string)"
		guard let url = URL(string: withScheme) else { return nil }
		guard url.host()?.contains(/\w.\w/) == true else { return nil }
		return url
	}
}

struct CircleButton: View {
	var label: Label<Text, Image>
	var action: () -> Void
	
	@ScaledMetric private var size = 32
	@Environment(\.isEnabled) private var isEnabled
	
	init(_ label: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) {
		self.label = .init(label, systemImage: systemImage)
		self.action = action
	}
	
	var body: some View {
		Button(action: action) {
			label
				.labelStyle(.iconOnly)
				.frame(width: size, height: size)
				.background {
					Circle()
						.foregroundStyle(.quaternary)
				}
				.foregroundStyle(.accent)
		}
		.saturation(isEnabled ? 1 : 0)
		.buttonStyle(.plain)
	}
}

struct RevisionView: View {
	@Binding var revision: Recipe.Revision
	@Environment(\.hasRegularWidth) var hasRegularWidth
	
	var body: some View {
		if hasRegularWidth {
			HStack(alignment: .top, spacing: 16) {
				ingredients()
				
				Divider()
				
				process()
			}
			
			notes()
		} else {
			ingredients()
			
			process()
			
			notes()
		}
	}
	
	private func ingredients() -> some View {
		RecipeSection("Ingredients", systemImage: "carrot") {
			Button("Edit") {} // TODO
		} content: {
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
	
	private func process() -> some View {
		RecipeSection("Process", systemImage: "list.number") {
			Button("Edit") {} // TODO
		} content: {
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
	
	private func notes() -> some View {
		RecipeSection("Notes", systemImage: "note") {
			Button {
				revision.notes.insert(.init(), at: 0)
			} label: {
				Label("Add Note", systemImage: "plus")
			}
			.labelStyle(.iconOnly)
		} content: {
			if revision.notes.isEmpty {
				Text("Press \(Image(systemName: "plus")) above to add a note.")
					.font(.footnote)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity)
			} else {
				ForEach($revision.notes) { $note in
					VStack {
						HStack(alignment: .lastTextBaseline) {
							Text(note.dateCreated, format: .dateTime)
								.foregroundStyle(.secondary)
								.font(.footnote)
							
							Spacer()
							
							Button {
								revision.notes.removeAll { $0.id == note.id }
							} label: {
								Image(systemName: "trash")
							}
						}
						Divider()
						TextField("Note", text: $note.contents, axis: .vertical)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
				}
			}
		}
	}
}

private struct RecipeSection<HeaderButton: View, Content: View>: View {
	var heading: LocalizedStringKey
	var icon: Image
	var headerButton: HeaderButton
	var content: Content
	
	init(
		_ heading: LocalizedStringKey, systemImage: String, 
		@ViewBuilder headerButton: () -> HeaderButton,
		@ViewBuilder content: () -> Content
	) {
		self.heading = heading
		self.icon = Image(systemName: systemImage)
		self.headerButton = headerButton()
		self.content = content()
	}
	
	var body: some View {
		VStack(spacing: 8) {
			let boxPadding: CGFloat = 12
			
			HStack {
				Label {
					Text(heading)
				} icon: {
					icon.foregroundStyle(.accent)
				}
				
				Spacer()
				
				headerButton
			}
			.font(.headline)
			.padding(.horizontal, boxPadding)
			
			content
				.padding(boxPadding)
				.background(Color.textBackground, in: RoundedRectangle(cornerRadius: boxPadding))
		}
	}
}

#Preview("Example Recipe") {
	PreviewWrapper(recipe: .example)
}

#Preview("Empty") {
	PreviewWrapper(recipe: .init())
}

private struct PreviewWrapper: View {
	@State var recipe: Recipe
	
	var body: some View {
		ContentView(recipe: $recipe)
	}
}
