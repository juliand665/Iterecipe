import SwiftUI
import Observation
import Combine

struct UndoRedoButtons: View {
	@Environment(ObservableUndoManager.self) private var undoManager
	
	var body: some View {
#if !os(macOS)
		Button {
			undoManager.undo()
		} label: {
			Label("Undo", systemImage: "arrow.uturn.backward.circle")
		}
		.disabled(!undoManager.canUndo)
		
		Button {
			undoManager.redo()
		} label: {
			Label("Redo", systemImage: "arrow.uturn.forward.circle")
		}
		.disabled(!undoManager.canRedo)
#endif
	}
}

@Observable
final class ObservableUndoManager {
	private(set) var manager: UndoManager?
	private(set) var canUndo = false
	private(set) var canRedo = false
	
	private var observation: AnyCancellable?
	
	func observe(_ manager: UndoManager) {
		self.manager = manager
		
		let nc = NotificationCenter.default
		observation = nc.publisher(for: .NSUndoManagerWillCloseUndoGroup, object: manager).merge(
			with: nc.publisher(for: .NSUndoManagerDidUndoChange, object: manager),
			nc.publisher(for: .NSUndoManagerDidRedoChange, object: manager)
		).sink { [weak self] _ in
			self?.canUndo = manager.canUndo
			self?.canRedo = manager.canRedo
		}
	}
	
	func undo() {
		manager!.undo()
	}
	
	func redo() {
		manager!.redo()
	}
}
