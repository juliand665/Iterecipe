import SwiftUI

struct CircleButton: View {
	var label: Label<Text, Image>
	var action: () -> Void
	
	@ScaledMetric private var size = 32
	@Environment(\.isEnabled) private var isEnabled
	
	init(_ label: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) {
		self.label = .init(label, systemImage: systemImage)
		self.action = action
	}
	
	var body: some View {
		Button(action: action) {
			label
				.labelStyle(.iconOnly)
				.frame(width: size, height: size)
				.background {
					Circle()
						.foregroundStyle(.quaternary)
				}
				.foregroundStyle(.accent)
		}
		.saturation(isEnabled ? 1 : 0)
		.buttonStyle(.plain)
	}
}

#Preview {
	CircleButton("Example", systemImage: "umbrella") {}
}
