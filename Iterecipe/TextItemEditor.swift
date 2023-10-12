import SwiftUI

struct TextItemEditor: View {
	@Binding var items: [TextItem]
	var textPlaceholder: LocalizedStringKey
	var addButtonLabel: LocalizedStringKey
	
	@Environment(\.editMode) private var editMode
	@FocusState private var focusedItem: TextItem.ID?
	
	var body: some View {
		List {
			ForEach($items, editActions: .all) { $item in
				TextField(textPlaceholder, text: $item.text, axis: .vertical)
					.focused($focusedItem, equals: item.id)
					.disabled(editMode?.wrappedValue.isEditing == true)
					.onSubmit {
						let nextItem = items
							.drop { $0.id != item.id }
							.dropFirst()
							.first?.id
						if let nextItem {
							focusedItem = nextItem
						} else {
							let newItem = TextItem()
							items.append(newItem)
							focusedItem = newItem.id
						}
					}
			}
			
			Button {
				items.append(.init())
			} label: {
				Label(addButtonLabel, systemImage: "plus")
			}
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			EditButton()
		}
		.toolbar {
			HStack(spacing: 0) {
				UndoRedoButtons()
			}
		}
	}
}

#Preview("Example Ingredients") {
	NavigationStack {
		TextItemEditorPreview(items: Recipe.example.revisions.last!.ingredients)
	}
}

struct TextItemEditorPreview: View {
	@State var items: [TextItem]
	
	var body: some View {
		TextItemEditor(items: $items, textPlaceholder: "Item", addButtonLabel: "Add Ingredient")
			.navigationTitle("Ingredients")
	}
}
