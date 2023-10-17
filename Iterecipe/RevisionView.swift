import SwiftUI

struct RevisionView: View {
	@Binding var revision: Recipe.Revision
	@Environment(\.hasRegularWidth) var hasRegularWidth
	@Environment(ObservableUndoManager.self) var undoManager
	@State var checklist = Checklist()
	
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
				.environment(undoManager)
			}
		} content: {
			ChecklistView(items: revision.ingredients, completedItems: $checklist.completedIngredients)
		}
	}
	
	private func process() -> some View {
		RecipeSection("Process", systemImage: "list.number") {
			NavigationLink("Edit") {
				TextItemEditor(
					items: $revision.steps,
					textPlaceholder: "Step Description",
					addButtonLabel: "Add Step"
				)
				.navigationTitle("Steps")
				.environment(undoManager)
			}
		} content: {
			ChecklistView(items: revision.steps, completedItems: $checklist.completedSteps)
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

struct Checklist {
	var completedIngredients: Set<TextItem.ID> = []
	var completedSteps: Set<TextItem.ID> = []
}

struct ChecklistView: View {
	var items: [TextItem]
	@Binding var completedItems: Set<TextItem.ID>
	
	var body: some View {
		VStack(spacing: 12) {
			ForEach(items) { item in
				Button {
					completedItems.formSymmetricDifference([item.id])
				} label: {
					HStack {
						let isComplete = completedItems.contains(item.id)
						Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
							.imageScale(.large)
						
						Text(item.text)
							.frame(maxWidth: .infinity, alignment: .leading)
							.tint(.primary)
							.opacity(isComplete ? 0.5 : 1)
							.multilineTextAlignment(.leading)
					}
				}
				
				if item.id != items.last?.id {
					Divider()
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
