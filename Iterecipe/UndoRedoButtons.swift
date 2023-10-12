import SwiftUI

struct UndoRedoButtons: View {
	@Environment(\.undoManager) private var undoManager
	
	var body: some View {
#if !os(macOS)
		Button {
			undoManager!.undo()
		} label: {
			Label("Undo", systemImage: "arrow.uturn.backward.circle")
		}
		.disabled(undoManager?.canUndo != true)
		
		Button {
			undoManager!.redo()
		} label: {
			Label("Redo", systemImage: "arrow.uturn.forward.circle")
		}
		.disabled(undoManager?.canRedo != true)
#endif
	}
}
