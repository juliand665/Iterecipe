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
				VStack {
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
				}
				
				ProcessManagementControls(prompts: prompts, recipeTitle: recipe.title)
				
				VStack {
					revisionSwitcher()
					Divider()
				}
				
				RevisionView(revision: $recipe.revisions[revisionIndex], prompts: prompts)
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
	
	func revisionSwitcher() -> some View {
		HStack {
			CircleButton("Previous Revision", systemImage: "chevron.left") {
				withAnimation {
					revisionIndexFromEnd += 1
				}
			}
			.disabled(revisionIndexFromEnd >= recipe.revisions.count - 1)
			
			NavigationLink {
				RevisionListView(recipe: $recipe, revisionIndexFromEnd: $revisionIndexFromEnd)
					.environment(undoManager)
			} label: {
				HStack {
					Group {
						if revisionIndexFromEnd == 0 {
							Text("Current Revision")
						} else {
							Text("Revision \(revisionIndex + 1)/\(recipe.revisions.count)")
						}
					}
					.tint(.primary)
					
					Image(systemName: "chevron.down")
						.imageScale(.small)
				}
			}
			.frame(maxWidth: .infinity)
			
			if revisionIndexFromEnd == 0 {
				CircleButton("Add New Revision", systemImage: "plus") {
					withAnimation {
						recipe.addRevision()
					}
				}
			} else {
				CircleButton("Next Revision", systemImage: "chevron.right") {
					withAnimation {
						revisionIndexFromEnd -= 1
					}
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
