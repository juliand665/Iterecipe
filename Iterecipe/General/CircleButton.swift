import SwiftUI

extension ButtonStyle where Self == CircularButtonStyle {
	static func circular(padding: Double? = nil, isProminent: Bool = false) -> Self {
		.init(padding: padding, isProminent: isProminent)
	}
}

struct CircularButtonStyle: ButtonStyle {
	var padding: Double?
	var isProminent = false
	@ScaledMetric private var size = 36
	@Environment(\.isEnabled) private var isEnabled
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundStyle(isProminent ? .white : .accent)
			.labelStyle(.iconOnly)
			.frame(width: size, height: size)
			.padding(padding ?? 0)
			.background {
				Circle()
					.foregroundStyle(isProminent ? .primary : .quaternary)
			}
			.foregroundStyle(.accent)
			.saturation(isEnabled ? 1 : 0)
	}
}

#Preview {
	VStack {
		Button("Example", systemImage: "umbrella") {}
		Button("Example", systemImage: "checkmark") {}
			.disabled(true)
		Button("Example", systemImage: "checkmark") {}
			.buttonStyle(.circular(padding: 4))
		Group {
			Button("Example", systemImage: "cloud.rain") {}
			Button("Example", systemImage: "square.and.arrow.up") {}
				.disabled(true)
		}
		.buttonStyle(.circular(isProminent: true))
	}
	.buttonStyle(.circular())
}
