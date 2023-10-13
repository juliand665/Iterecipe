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
				itemRow($item: $item)
			}
			
			Button {
				items.append(.init())
			} label: {
				Label(addButtonLabel, systemImage: "plus")
			}
		}
		.scrollDismissesKeyboard(.interactively)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			EditButton()
		}
		.toolbar {
			HStack(spacing: 0) {
				UndoRedoButtons()
			}
		}
		.onChange(of: focusedItem) {
			if focusedItem == nil {
				items.removeAll { $0.text.isEmpty }
			}
		}
	}
	
	func itemRow(@Binding item: TextItem) -> some View {
		func advance() {
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
		
		return TextField(textPlaceholder, text: $item.text, axis: .vertical)
			.focused($focusedItem, equals: item.id)
			.disabled(editMode?.wrappedValue.isEditing == true)
			.submitLabel(.next)
			.onSubmit(advance)
			.onChange(of: item.text) {
				let trimmed = item.text.trimmingCharacters(in: .newlines)
				if trimmed.count != item.text.count {
					// pressed return
					item.text = trimmed
					advance()
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
