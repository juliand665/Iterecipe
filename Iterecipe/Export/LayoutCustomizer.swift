import SwiftUI

struct LayoutCustomizer: View {
	@Binding var layout: PrintLayout
	
	var body: some View {
		Form {
			Picker(selection: $layout.titleAlignment.animation()) {
				ForEach(TitleAlignment.allCases, id: \.self) {
					Text($0.label)
						.tag($0)
				}
			} label: {
				Text("Title Alignment")
			}
			
			VStack {
				Text("Image Layout")
					.frame(maxWidth: .infinity, alignment: .leading)
				
				ScrollView(.horizontal) {
					HStack {
						ForEach(ImageLayout.allCases, id: \.self) {
							ImageLayoutButton(
								currentLayout: $layout.imageLayout,
								layout: $0,
								titleAlignment: layout.titleAlignment
							)
						}
					}
				}
				.scrollIndicators(.hidden)
				.scrollClipDisabled()
			}
			.alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
			
			// TODO: image max size slider?
			
			// TODO: margins slider?
			
			SliderAndTextField(
				label: "Ingredients Width", systemImage: "arrow.left.and.right.square",
				value: $layout.ingredientsWidth, sliderRange: 100...500
			)
			
			VStack {
				HStack {
					Text("Page Size")
						.frame(maxWidth: .infinity, alignment: .leading)
					
					Menu {
						pageSizeButton("DIN A4", size: .dinA4)
						pageSizeButton("US Letter", size: .usLetter)
					} label: {
						switch layout.pageSize {
						case .dinA4:
							Text("Preset: DIN A4")
						case .usLetter:
							Text("Preset: US Letter")
						default:
							Text("Presets")
						}
					}
				}
				
				HStack {
					lengthField("Width", value: $layout.pageSize.width)
					Text("×")
					lengthField("Height", value: $layout.pageSize.height)
					Text("mm")
				}
				.labelsHidden()
				.textFieldStyle(.roundedBorder)
			}
			
			SliderAndTextField(
				label: "Scale Factor", systemImage: "arrow.up.left.and.down.right.magnifyingglass",
				value: $layout.scaleFactor, sliderRange: 2...8
			)
			
			Button("Reset to Defaults", role: .destructive) {
				layout = .init()
			}
		}
	}
	
	func pageSizeButton(_ label: LocalizedStringKey, size: PageSize) -> some View {
		Button {
			withAnimation {
				layout.pageSize = size
			}
		} label: {
			HStack {
				Text(label)
				
				if layout.pageSize == size {
					Image(systemName: "checkmark")
				}
			}
		}
	}
	
	func lengthField(_ label: LocalizedStringKey, value: Binding<Double>) -> some View {
		TextField(label, value: value, format: .number.precision(.fractionLength(1)))
			.multilineTextAlignment(.trailing)
	}
}

private struct SliderAndTextField: View {
	var label: LocalizedStringKey
	var systemImage: String
	@Binding var value: Double
	var sliderRange: ClosedRange<Double>
	
	var body: some View {
		VStack(spacing: 4) {
			HStack {
				Text(label)
				
				Spacer()
				
				TextField(value: $value, format: .number.precision(.fractionLength(1))) {
					Text(label)
				}
				.labelsHidden()
				.monospacedDigit()
				.multilineTextAlignment(.trailing)
				.frame(maxWidth: 100)
				.textFieldStyle(.roundedBorder)
			}
			
			Slider(value: $value, in: sliderRange)
		}
		.alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
	}
}

#Preview {
	LayoutCustomizerPreview()
}

private struct LayoutCustomizerPreview: View {
	@State var layout = PrintLayout()
	
	var body: some View {
		LayoutCustomizer(layout: $layout)
	}
}
