import SwiftUI

@MainActor
struct RevisionView: View {
	@Binding var revision: Recipe.Revision
	@Bindable var prompts: CookingPrompts
	
	@FocusState var focusedNote: Note.ID?
	
	@Environment(\.hasRegularWidth) private var hasRegularWidth
	@Environment(ObservableUndoManager.self) private var undoManager
	@Environment(ProcessManager.self) private var processManager
	@Environment(\.recipeURL) private var recipeURL
	
	private var checklistBinding: Binding<Checklist>? {
		// this is so silly
		processManager.process(forRecipeAt: recipeURL).map(Bindable.init(_:))?.checklist
	}
	
	func addNote() {
		let note = Note()
		revision.notes.insert(note, at: 0)
		focusedNote = note.id
	}
	
	var body: some View {
		VStack(spacing: 32) {
			if hasRegularWidth {
				HStack(alignment: .top, spacing: 16) {
					ingredients()
					
					Divider()
					
					process()
				}
			} else {
				ingredients()
				
				process()
			}
			
			notes()
		}
		.confirmationDialog("Add Note?", isPresented: $prompts.isShowingNotePrompt) {
			Button("Add Note") {
				withAnimation {
					addNote()
				}
			}
			
			Button("No Thanks", role: .cancel) {}
		} message: {
			Text("It can be helpful to reflect on how your recipe turned out in order to drive future improvements!")
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
			ChecklistView(
				items: revision.ingredients, 
				completedItems: checklistBinding?.completedIngredients,
				showStartPrompt: { prompts.isShowingStartPrompt = true }
			)
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
			ChecklistView(
				items: revision.steps,
				completedItems: checklistBinding?.completedSteps,
				showStartPrompt: { prompts.isShowingStartPrompt = true }
			)
		}
	}
	
	private func notes() -> some View {
		RecipeSection("Notes", systemImage: "note.text") {
			Button("Add Note", systemImage: "plus") {
				withAnimation {
					addNote()
				}
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
						
						Button("Remove Note", systemImage: "trash") {
							withAnimation {
								revision.notes.removeAll { $0.id == note.id }
							}
						}
						.labelStyle(.iconOnly)
					}
					
					Divider()
					
					TextField("Note", text: $note.contents, axis: .vertical)
						.focused($focusedNote, equals: note.id)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			}
		}
	}
}

extension Transition where Self == ScaleTransition {
	/// unlike identity, remains visible for the entire duration of the transition, so you can e.g. wipe over it
	static var stay: Self { .init(0.9999) } // 1 is hardcoded to identity
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
			.padding(.horizontal, .boxPadding)
			.padding(.bottom, .boxPadding - 8)
			
			content
				.padding(.boxPadding)
				.background(Color.textBackground, in: RoundedRectangle(cornerRadius: .boxPadding))
		}
	}
}

extension CGFloat {
	static let boxPadding: Self = 12
}

// just reuse main preview

#Preview("Example Recipe") {
	ContentViewPreview(recipe: .example)
		.environment(ProcessManager())
}

#Preview("Empty") {
	ContentViewPreview(recipe: .init())
		.environment(ProcessManager())
}
