import SwiftUI
import PhotosUI

@MainActor
struct ContentView: View {
	@Binding var recipe: Recipe
	
	@State var revisionIndexFromEnd = 0
	@State var prompts = CookingPrompts()
	
	@Environment(\.recipeURL) private var recipeURL
	@Environment(\.undoManager) private var nsUndoManager
	@State var undoManager = ObservableUndoManager()
	
	var revisionIndex: Int {
		recipe.revisions.count - 1 - revisionIndexFromEnd
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 32) {
				VStack(spacing: 8) {
					EditableImage(image: $recipe.image)
					
					Divider()
					
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
					
					Divider()
					
					NavigationLink {
						ExportDesigner(recipe: recipe, revision: recipe.revisions[revisionIndex])
					} label: {
						HStack {
							Label {
								Text("Print/Export PDF")
									.tint(.primary)
							} icon: {
								Image(systemName: "printer")
							}
							
							Spacer()
							
							Image(systemName: "chevron.right")
								.imageScale(.small)
								.foregroundStyle(.tertiary)
								.tint(.primary)
						}
						.padding(6)
					}
					.fontWeight(.medium)
					
					Divider()
					
					RevisionSwitcher(recipe: $recipe, revisionIndexFromEnd: $revisionIndexFromEnd)
				}
				
				ProcessManagementControls(prompts: prompts, recipeTitle: recipe.title)
				
				RevisionView(revision: $recipe.revisions[revisionIndex], prompts: prompts)
			}
			.padding()
			.textFieldStyle(.plain)
		}
		.scrollDismissesKeyboard(.interactively)
		.background(Color.canvasBackground)
		//.textFieldsWithoutFocusRing()
		.buttonStyle(.borderless)
		.background( // cheeky keyboard shortcuts lol
			Group {
				Button("Done", action: unfocusTextField).keyboardShortcut(.escape, modifiers: [])
				Button("Done", action: unfocusTextField).keyboardShortcut(.return, modifiers: .command)
			}
				.opacity(0)
		)
		.toolbar {
			HStack {
				UndoRedoButtons()
			}
		}
		.environment(undoManager)
		.onChange(of: nsUndoManager, initial: true) {
			guard let nsUndoManager else { return } // happens sometimes in previews
			undoManager.observe(nsUndoManager)
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
}

private struct RevisionSwitcher: View {
	@Binding var recipe: Recipe
	@Binding var revisionIndexFromEnd: Int
	@State var isShowingPicker = false
	
	@Environment(ObservableUndoManager.self) private var undoManager
	
	var body: some View {
		HStack {
			Button("Previous Revision", systemImage: "chevron.left") {
				withAnimation {
					revisionIndexFromEnd += 1
				}
			}
			.disabled(revisionIndexFromEnd >= recipe.revisions.count - 1)
			
			Button {
				isShowingPicker = true
			} label: {
				HStack {
					if revisionIndexFromEnd == 0 {
						Text("Current Revision")
					} else {
						let index = recipe.revisions.count - revisionIndexFromEnd
						Text("Revision \(index)/\(recipe.revisions.count)")
					}
					
					Image(systemName: "chevron.down")
						.imageScale(.small)
						.foregroundStyle(.accent)
				}
			}
			.frame(maxWidth: .infinity)
			.buttonStyle(.plain)
			
			if revisionIndexFromEnd == 0 {
				Button("Add New Revision", systemImage: "plus") {
					withAnimation {
						recipe.addRevision()
					}
				}
			} else {
				Button("Next Revision", systemImage: "chevron.right") {
					withAnimation {
						revisionIndexFromEnd -= 1
					}
				}
			}
		}
		.labelStyle(.iconOnly)
		.buttonStyle(.circular())
		.fontWeight(.medium)
		.sheet(isPresented: $isShowingPicker) {
			NavigationStack {
				RevisionListView(recipe: $recipe, revisionIndexFromEnd: $revisionIndexFromEnd)
					.toolbar {
						ToolbarItem(placement: .navigation) {
							Button("Done") {
								isShowingPicker = false
							}
							.fontWeight(.medium)
						}
					}
			}
			.environment(undoManager)
		}
	}
}

private struct EditableImage: View {
	@Binding var image: RecipeImage?
	@State var isPickingImage = false
	@State var selectedImage: PhotosPickerItem?
	@State var imageError = ErrorContainer()
	
	var body: some View {
		VStack {
			if let image {
				image.image
					.resizable()
					.clipShape(RoundedRectangle(cornerRadius: 12))
					.aspectRatio(contentMode: .fit)
					.frame(maxHeight: 300)
					.contextMenu {
						Button("Replace Image", systemImage: "photo.on.rectangle.angled") {
							isPickingImage = true
						}
						
						Button("Remove Image", systemImage: "xmark") {
							self.image = nil
						}
					}
					.padding(.bottom, 4)
			} else {
				Button("Add Image", systemImage: "photo.badge.plus") {
					isPickingImage = true
				}
			}
		}
		.photosPicker(
			isPresented: $isPickingImage, selection: $selectedImage,
			matching: .images, preferredItemEncoding: .current
		)
		.task(id: selectedImage) {
			guard let selectedImage else { return }
			$imageError.task(errorTitle: "Image could not be set!") {
				let image = try await selectedImage.loadTransferable(type: RecipeImage.self)
				guard self.selectedImage == selectedImage else { return } // changed in the meantime
				self.selectedImage = nil
				self.image = image
			}
		}
	}
}

#Preview("Example Recipe") {
	ContentViewPreview(recipe: .example)
}

#Preview("Empty") {
	ContentViewPreview(recipe: .init())
}

struct ContentViewPreview: View {
	@State var recipe: Recipe
	
	var body: some View {
		NavigationStack {
			ContentView(recipe: $recipe)
				.environment(ProcessManager())
		}
	}
}
