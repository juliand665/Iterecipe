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
		RecipeSection("Ingredients", systemImage: "basket") {
			NavigationLink("Edit") {
				TextItemEditor(
					items: $revision.ingredients,
					textPlaceholder: "Ingredient",
					addButtonLabel: "Add Ingredient"
				)
				.navigationTitle("Ingredients")
			}
		} content: {
			ForEach(revision.ingredients) { ingredient in
				Text(ingredient.text)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
	}
	
	@State private var isEditingProcess = false
	
	private func process() -> some View {
		RecipeSection("Process", systemImage: "list.number") {
			NavigationLink("Edit") {
				TextItemEditor(
					items: $revision.steps,
					textPlaceholder: "Step Description",
					addButtonLabel: "Add Step"
				)
				.navigationTitle("Steps")
			}
		} content: {
			ForEach(revision.steps) { step in
				Text(step.text)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
	}
	
	private func notes() -> some View {
		RecipeSection("Notes", systemImage: "note.text") {
			Button {
				withAnimation {
					revision.notes.insert(.init(), at: 0)
				}
			} label: {
				Label("Add Note", systemImage: "plus")
			}
			.labelStyle(.iconOnly)
		} content: {
			ForEach($revision.notes) { $note in
				VStack {
					HStack(alignment: .lastTextBaseline) {
						Text(note.dateCreated, format: .dateTime)
							.foregroundStyle(.secondary)
							.font(.footnote)
						
						Spacer()
						
						Button {
							withAnimation {
								revision.notes.removeAll { $0.id == note.id }
							}
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
			.font(.title3.weight(.semibold))
			.padding(.horizontal, boxPadding)
			.padding(.bottom, boxPadding - 8)
			
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
