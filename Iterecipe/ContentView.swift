import SwiftUI
import PhotosUI

@MainActor
struct ContentView: View {
	@Binding var recipe: Recipe
	@State var revisionIndexFromEnd = 0
	@State var isPickingImage = false
	@State var selectedImage: PhotosPickerItem?
	@State var imageError = ErrorContainer()
	
	var revisionIndex: Int {
		recipe.revisions.count - 1 - revisionIndexFromEnd
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 32) {
				VStack {
					recipeImage()
					
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
			HStack {
				UndoRedoButtons()
			}
		}
	}
	
	func recipeImage() -> some View {
		VStack {
			if let image = recipe.image {
				image.image
					.resizable()
					.clipShape(RoundedRectangle(cornerRadius: 12))
					.aspectRatio(contentMode: .fit)
					.frame(maxHeight: 300)
					.contextMenu {
						Button {
							isPickingImage = true
						} label: {
							Label("Replace Image", systemImage: "photo.on.rectangle.angled")
						}
						
						Button {
							recipe.image = nil
						} label: {
							Label("Remove Image", systemImage: "xmark")
						}
					}
					.padding(.bottom, 4)
			} else {
				Button {
					isPickingImage = true
				} label: {
					Label("Add Image", systemImage: "photo.badge.plus")
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
				recipe.image = image
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

private struct CircleButton: View {
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

#Preview("Example Recipe") {
	ContentViewPreview(recipe: .example)
}

#Preview("Empty") {
	ContentViewPreview(recipe: .init())
}

struct ContentViewPreview: View {
	@State var recipe: Recipe
	
	var body: some View {
		ContentView(recipe: $recipe)
	}
}
