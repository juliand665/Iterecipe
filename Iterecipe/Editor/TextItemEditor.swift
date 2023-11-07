import SwiftUI

struct TextItemEditor: View {
	@Binding var items: [TextItem]
	var textPlaceholder: LocalizedStringKey
	var addButtonLabel: LocalizedStringKey
	
	#if os(iOS)
	@Environment(\.editMode) private var editMode
	#endif
	@FocusState private var focusedItem: TextItem.ID?
	
	var body: some View {
		List {
			ForEach($items, editActions: .all) { $item in
				itemRow($item: $item)
			}
			
			Button(addButtonLabel, systemImage: "plus") {
				items.append(.init())
			}
		}
		.scrollDismissesKeyboard(.interactively)
#if os(iOS)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			EditButton()
		}
#endif
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
			let currentIndex = items.firstIndex { $0.id == item.id }!
			let newItem = TextItem()
			items.insert(newItem, at: currentIndex + 1)
			focusedItem = newItem.id
		}
		
		return TextField(textPlaceholder, text: $item.text, axis: .vertical)
			.focused($focusedItem, equals: item.id)
#if os(iOS)
			.disabled(editMode?.wrappedValue.isEditing == true)
#endif
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
