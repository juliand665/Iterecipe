import SwiftUI
import Algorithms

struct RevisionListView: View {
	@Binding var recipe: Recipe
	@Binding var revisionIndexFromEnd: Int
	
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		List {
			ForEach(recipe.revisions.indexed(), id: \.element.id) { item in
				let (index, revision) = item
				let indexFromEnd = recipe.revisions.count - index - 1
				Section {
					Button {
						revisionIndexFromEnd = indexFromEnd
						// TODO: dismiss?
					} label: {
						let isActive = revisionIndexFromEnd == indexFromEnd
						Label {
							HStack {
								Text(index == 0 ? "Initial Version" : "Revision \(index + 1)")
									.font(.headline)
									.tint(.primary)
								
								Spacer()
								
								Group {
									if !revision.notes.isEmpty {
										Text("\(revision.notes.count)")
										Image(systemName: "note.text")
									}
								}
								.foregroundStyle(Color.secondary)
							}
						} icon: {
							Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
						}
					}
					
					if index > 0 {
						let previous = recipe.revisions[index - 1]
						let ingredientDiff = textItemDiff(current: revision.ingredients, previous: previous.ingredients)
						let processDiff = textItemDiff(current: revision.steps, previous: previous.steps)
						
						if ingredientDiff.isEmpty, processDiff.isEmpty {
							Text("Identical to previous revision.")
								.foregroundStyle(.secondary)
						} else {
							VStack {
								diffView("Ingredient Changes", for: ingredientDiff)
								diffView("Process Changes", for: processDiff)
							}
						}
					}
					
					Button("Delete Revision", systemImage: "trash") {
						withAnimation {
							_ = recipe.revisions.remove(at: index)
						}
					}
					.foregroundStyle(.red)
					.disabled(recipe.revisions.count == 1)
				} header: {
					Text(revision.dateCreated, format: .dateTime)
				}
			}
			
			Section {
				Button("Add New Revision", systemImage: "plus") {
					withAnimation {
						recipe.addRevision()
					}
				}
			}
		}
		.sensoryFeedback(.selection, trigger: revisionIndexFromEnd)
		.navigationTitle("Recipe Revisions")
		#if os(iOS)
		.navigationBarTitleDisplayMode(.inline)
		#endif
		.toolbar {
			HStack {
				UndoRedoButtons()
			}
		}
	}
	
	@ViewBuilder
	func diffView(_ heading: LocalizedStringKey, for changes: [Change]) -> some View {
		if !changes.isEmpty {
			VStack(spacing: 12) {
				Text(heading)
					.font(.subheadline.weight(.medium))
				Divider()
				VStack(spacing: 16) {
					ForEach(changes) {
						ChangeView(change: $0)
					}
				}
			}
			.alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
			.padding(.vertical)
		}
	}
	
	func textItemDiff(current: [TextItem], previous: [TextItem]) -> [Change] {
		let idChanges = current.map(\.id).difference(from: previous.map(\.id)).inferringMoves()
		var insertions = idChanges.insertions[...]
		var removals = idChanges.removals[...]
		var indexInCurrent = 0, indexInPrevious = 0
		var changes: [Change] = []
		while current.indices.contains(indexInCurrent) || previous.indices.contains(indexInPrevious) {
			while case .remove(let offset, let id, let newIndex) = removals.first, offset <= indexInPrevious {
				indexInPrevious += 1
				removals.removeFirst()
				
				guard newIndex == nil else { continue } // move
				
				let item = previous[offset]
				assert(item.id == id)
				
				changes.append(.removal(item))
			}
			
			while case .insert(let offset, let id, let oldIndex) = insertions.first, offset <= indexInCurrent {
				indexInCurrent += 1
				insertions.removeFirst()
				
				let item = current[offset]
				assert(item.id == id)
				
				if let oldIndex {
					let oldItem = previous[oldIndex]
					assert(oldItem.id == id)
					changes.append(.edit(old: oldItem, new: item, wasMoved: true))
				} else {
					changes.append(.insertion(item))
				}
			}
			
			guard indexInCurrent < current.endIndex, indexInPrevious < previous.endIndex else {
				assert(indexInCurrent == current.endIndex)
				assert(indexInPrevious == previous.endIndex)
				break
			}
			
			let new = current[indexInCurrent]
			let old = previous[indexInPrevious]
			assert(new.id == old.id)
			if new.text != old.text {
				changes.append(.edit(old: old, new: new, wasMoved: false))
			}
			
			indexInCurrent += 1
			indexInPrevious += 1
		}
		return changes
	}
	
	enum Change: Identifiable {
		case removal(TextItem)
		case insertion(TextItem)
		case edit(old: TextItem, new: TextItem, wasMoved: Bool)
		
		var id: TextItem.ID { // TODO: does it make sense to reuse that here?
			switch self {
			case .removal(let item): item.id
			case .insertion(let item): item.id
			case .edit(old: _, new: let item, wasMoved: _): item.id
			}
		}
	}
	
	struct ChangeView: View {
		var change: Change
		
		@ScaledMetric private var symbolSize = 24
		
		var body: some View {
			let divider = Capsule().frame(height: 1)
				.foregroundStyle(.accent)
				.alignmentGuide(.change) { $0.height / 2 }
			
			HStack(alignment: .change, spacing: 0) {
				let description = VStack(alignment: .leading, spacing: 4) {
					switch change {
					case .removal(let item):
						Text(item.text)
							.foregroundStyle(.secondary)
						divider
						Text("removed")
							.foregroundStyle(.accent)
					case .insertion(let item):
						Text("added")
							.foregroundStyle(.accent)
						divider
						Text(item.text)
					case .edit(let old, let new, _):
						if new.text != old.text {
							Text(old.text)
								.foregroundStyle(.secondary)
							divider
							Text(new.text)
						} else {
							HStack {
								Text(new.text)
								divider
									.frame(minWidth: 10)
									.layoutPriority(-1)
								Text("moved")
									.foregroundStyle(.accent)
									.layoutPriority(1)
							}
						}
					}
				}
					.lineLimit(1)
				
				// size based on the non-scrollable version
				description
					.hidden()
					.overlay {
						// need geometry reader in order to set min width appropriately
						GeometryReader { geometry in
							ScrollView(.horizontal) {
								description
									.frame(minWidth: geometry.size.width)
							}
							.scrollBounceBehavior(.basedOnSize, axes: .horizontal)
							.scrollIndicators(.hidden)
						}
					}
				
				Spacer()
				
				Group {
					switch change {
					case .removal:
						Image(systemName: "delete.left")
					case .insertion:
						Image(systemName: "plus")
					case .edit(_, _, let wasMoved):
						Image(systemName: wasMoved ? "arrow.left" : "pencil.line")
					}
				}
				.foregroundStyle(.accent)
				.frame(minWidth: symbolSize)
			}
			.font(.footnote)
		}
	}
}

private extension VerticalAlignment {
	static let change = VerticalAlignment(ChangeAlignment.self)
	
	private enum ChangeAlignment: AlignmentID {
		static func defaultValue(in context: ViewDimensions) -> CGFloat {
			context[VerticalAlignment.center]
		}
	}
}

#Preview {
	RevisionListViewPreview(recipe: .example, revisionIndexFromEnd: 0)
}

struct RevisionListViewPreview: View {
	@State var recipe: Recipe
	@State var revisionIndexFromEnd: Int
	
	var body: some View {
		NavigationStack {
			RevisionListView(recipe: $recipe, revisionIndexFromEnd: $revisionIndexFromEnd)
		}
		.environment(ObservableUndoManager())
	}
}
