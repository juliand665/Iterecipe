import SwiftUI
//import Introspect

/*
extension View {
	func textFieldsWithoutFocusRing() -> some View {
#if os(macOS)
		return introspectTextField { $0.focusRingType = .none }
#else
		return self
#endif
	}
}
*/

func unfocusTextField() {
	DispatchQueue.main.async {
#if os(macOS)
		NSApp.keyWindow?.makeFirstResponder(nil)
#else
		UIApplication.shared.sendAction(
			#selector(UIResponder.resignFirstResponder),
			to: nil, from: nil, for: nil
		)
#endif
	}
}

extension Color {
#if os(macOS)
	static let recipeBackground = Self(.textBackgroundColor)
#else
	static let recipeBackground = Self(.systemBackground)
#endif
}

extension EnvironmentValues {
	var hasRegularWidth: Bool {
#if os(macOS)
		return true
#else
		return horizontalSizeClass == .regular
#endif
	}
}
