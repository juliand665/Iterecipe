import SwiftUI

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

// just reuse main preview

#Preview("Example Recipe") {
	ContentViewPreview(recipe: .example)
}

#Preview("Empty") {
	ContentViewPreview(recipe: .init())
}
