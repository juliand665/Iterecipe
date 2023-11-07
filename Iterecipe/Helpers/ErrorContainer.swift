import SwiftUI

struct ErrorContainer {
	var defaultTitle: LocalizedStringKey?
	var error: DisplayedError? {
		didSet {
			isPresented = error != nil
		}
	}
	var isPresented = false
	
	var currentTitle: LocalizedStringKey {
		error?.title ?? defaultTitle ?? "An Error Occurred!"
	}
	
	mutating func `try`<T>(
		errorTitle: LocalizedStringKey? = nil,
		perform action: () throws -> T
	) -> T? {
		do {
			let result = try action()
			error = nil
			return result
		} catch {
			self.error = .init(error: error, title: errorTitle)
			print("try failed:", currentTitle)
			print(error)
			return nil
		}
	}
	
	struct DisplayedError {
		var error: Error
		var title: LocalizedStringKey?
		var isPresented = true
	}
}

extension Binding<ErrorContainer> {
	@MainActor
	func `try`<T: Sendable>(
		errorTitle: LocalizedStringKey? = nil,
		perform action: @MainActor () async throws -> T
	) async throws -> T {
		do {
			let result = try await action()
			wrappedValue.error = nil
			return result
		} catch {
			guard !Task.isCancelled else {
				throw CancellationError()
			}
			wrappedValue.error = .init(error: error, title: errorTitle)
			print("try failed:", wrappedValue.currentTitle)
			print(error)
			throw error
		}
	}
	
	@MainActor
	@discardableResult
	func task<T: Sendable>(
		errorTitle: LocalizedStringKey? = nil,
		perform action: @MainActor @escaping () async throws -> T
	) -> Task<T, Error> {
		Task {
			try await self.try(errorTitle: errorTitle, perform: action)
		}
	}
}

extension View {
	func alert(for error: Binding<ErrorContainer>) -> some View {
		alert(
			error.wrappedValue.currentTitle,
			isPresented: error.isPresented,
			presenting: error.wrappedValue.error
		) { _ in
			Button("OK") {}
		} message: { error in
			if let localized = error.error as? LocalizedError {
				Text(localized.recoverySuggestion ?? localized.failureReason ?? localized.localizedDescription)
			} else {
				Text(error.error.localizedDescription)
			}
		}
	}
}
