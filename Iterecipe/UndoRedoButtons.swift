import SwiftUI

struct UndoRedoButtons: View {
	@Environment(\.undoManager) private var undoManager
	@State private var updateTrigger = false
	
	var body: some View {
#if !os(macOS)
		if let undoManager {
			let _ = updateTrigger // trigger view updates when this is toggled
			
			Button {
				undoManager.undo()
			} label: {
				Label("Undo", systemImage: "arrow.uturn.backward.circle")
			}
			.disabled(!undoManager.canUndo)
			.onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerWillCloseUndoGroup, object: undoManager)) { _ in updateTrigger.toggle() }
			.onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerWillUndoChange, object: undoManager)) { _ in updateTrigger.toggle() }
			.onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerWillRedoChange, object: undoManager)) { _ in updateTrigger.toggle() }
			
			Button {
				undoManager.redo()
			} label: {
				Label("Redo", systemImage: "arrow.uturn.forward.circle")
			}
			.disabled(!undoManager.canRedo)
		}
#endif
	}
}
