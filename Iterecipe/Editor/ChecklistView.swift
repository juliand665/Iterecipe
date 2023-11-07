import SwiftUI

struct ChecklistView: View {
	var items: [TextItem]
	var completedItems: Binding<Set<TextItem.ID>>?
	var showStartPrompt: () -> Void
	
	var body: some View {
		VStack(spacing: .boxPadding) {
			ForEach(items) { item in
				Button {
					if let completedItems {
						completedItems.wrappedValue.formSymmetricDifference([item.id])
					} else {
						showStartPrompt()
					}
				} label: {
					HStack {
						let isComplete = completedItems?.wrappedValue.contains(item.id)
						
						if let isComplete {
							Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
								.imageScale(.large)
								.foregroundStyle(.accent)
						}
						
						Text(item.text)
							.frame(maxWidth: .infinity, alignment: .leading)
							.tint(.primary)
							.opacity(isComplete == true ? 0.5 : 1)
							.multilineTextAlignment(.leading)
					}
					.contentShape(Rectangle())
				}
				.buttonStyle(.plain)
				.sensoryFeedback(trigger: completedItems?.wrappedValue.contains(item.id)) { didContain, contains in
					guard let _ = didContain, let contains else { return nil }
					return contains ? .success : .selection
				}
				
				if item.id != items.last?.id {
					Divider()
				}
			}
			
			if items.isEmpty {
				Text("Nothing yet!")
					.font(.footnote)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity)
			}
		}
	}
}
