import SwiftUI

@MainActor
struct RevisionView: View {
	@Binding var revision: Recipe.Revision
	var recipeURL: URL?
	
	@State var isShowingStartPrompt = false
	@State var isShowingNotePrompt = false
	@FocusState var focusedNote: Note.ID?
	
	@Environment(\.hasRegularWidth) private var hasRegularWidth
	@Environment(ObservableUndoManager.self) private var undoManager
	@Environment(ProcessManager.self) private var processManager
	
	var currentProcess: Process? {
		recipeURL.flatMap(processManager.process(forRecipeAt:))
	}
	
	private var checklistBinding: Binding<Checklist>? {
		currentProcess.map(Bindable.init(_:))?.checklist
	}
	
	func addNote() {
		let note = Note()
		revision.notes.insert(note, at: 0)
		focusedNote = note.id
	}
	
	var body: some View {
		VStack(spacing: 32) {
			checklistControls()
			
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
		.confirmationDialog("Start Cooking?", isPresented: $isShowingStartPrompt, titleVisibility: .visible) {
			startCookingButton()
		} message: {
			// iOS currently seems to only show the first text item, so let's make sure the hint shows up if it applies
			saveToStartCookingHint()
			Text("Start cooking this recipe to check off ingredients & steps as you go!")
		}
		.confirmationDialog("Add Note?", isPresented: $isShowingNotePrompt) {
			Button("Add Note") {
				withAnimation {
					addNote()
				}
			}
		} message: {
			Text("It can be very helpful to reflect on how your recipe turned out in order to drive future improvements!")
		}
	}
	
	private func startCookingButton() -> some View {
		Button {
			withAnimation {
				processManager.startProcess(forRecipeAt: recipeURL!)
			}
		} label: {
			Label("Start Cooking", systemImage: "stove")
		}
		.disabled(recipeURL == nil)
	}
	
	@ViewBuilder
	private func saveToStartCookingHint() -> some View {
		if recipeURL == nil {
			Text("Recipe must be saved as a file in order to track progress.")
		}
	}
	
	private func checklistControls() -> some View {
		VStack(spacing: .boxPadding) {
			if let currentProcess {
				Button {
					withAnimation {
						processManager.endProcess(forRecipeAt: currentProcess.recipeURL)
						isShowingNotePrompt = true
					}
				} label: {
					Label("Finish Cooking", systemImage: "checkmark")
				}
				.buttonStyle(.borderedProminent)
				
				ReminderView()
			} else {
				startCookingButton()
					.buttonStyle(.borderedProminent)
				
				saveToStartCookingHint()
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
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
				showStartPrompt: { isShowingStartPrompt = true }
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
				showStartPrompt: { isShowingStartPrompt = true }
			)
		}
	}
	
	private func notes() -> some View {
		RecipeSection("Notes", systemImage: "note.text") {
			Button {
				withAnimation {
					addNote()
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
						.focused($focusedNote, equals: note.id)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			}
		}
	}
	
	struct ReminderView: View {
		@State var isShowingReminderInfo = false
		@State var hours = 4
		
		var body: some View {
			VStack(spacing: 0) {
				Button {
					withAnimation {
						isShowingReminderInfo.toggle()
					}
				} label: {
					HStack(spacing: 12) {
						Label {
							Text("Remind Me")
								.tint(.primary)
						} icon: {
							Image(systemName: "bell")
						}
						
						if isShowingReminderInfo {
							Spacer()
						}
						
						Image(systemName: "chevron.down")
							.rotationEffect(.degrees(isShowingReminderInfo ? 0 : -90))
					}
				}
				.font(.headline.weight(.medium))
				.padding(.boxPadding)
				
				if isShowingReminderInfo {
					Divider()
					
					VStack(spacing: .boxPadding) {
						Text("Iterecipe can remind you later, after your meal, to add a note reflecting on how this recipe came out and perhaps what changes to make next time.")
							.font(.footnote)
						
						Divider()
						
						// TODO: show different UI if reminder set
						HStack {
							Button("Remind Me") {
								// TODO: implement!
							}
							.buttonStyle(.borderedProminent)
							
							Text("in **^[\(hours) hours](inflect: true)**")
							
							Spacer()
							
							Stepper(value: $hours, in: 1...24) {}
								.labelsHidden()
						}
					}
					.padding(.boxPadding)
					.transition(.stay)
				}
			}
			.background(Color.textBackground)
			.clipShape(RoundedRectangle(cornerRadius: .boxPadding))
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
