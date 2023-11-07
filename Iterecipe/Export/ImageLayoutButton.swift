import SwiftUI

struct ImageLayoutButton: View {
	@Binding var currentLayout: ImageLayout
	var layout: ImageLayout
	var titleAlignment: TitleAlignment
	
	@Namespace var geometryNamespace
	
	var body: some View {
		let shape = RoundedRectangle(cornerRadius: 8)
		let isActive = currentLayout == layout
		
		Button {
			withAnimation {
				currentLayout = layout
			}
		} label: {
			icon()
				.padding(8)
				.frame(width: 80, height: 80)
				.background {
					shape.fill(.primary.opacity(0.1))
				}
				.foregroundStyle(isActive ? .accent : .primary.opacity(0.5))
				.clipShape(shape)
				.opacity(0.6)
				.overlay {
					shape.strokeBorder(
						isActive ? .accent : .primary.opacity(0.3),
						lineWidth: isActive ? 2 : 1
					)
				}
		}
		.buttonStyle(.plain)
	}
	
	@ViewBuilder
	func icon() -> some View {
		let photo = Image(systemName: "photo")
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		let text = RoundedRectangle(cornerRadius: 4)
		let title = text.frame(height: 6)
			.matchedGeometryEffect(id: "title", in: geometryNamespace)
		
		let titleIfOnTop = Group {
			if titleAlignment != .aboveProcess {
				title
			}
		}
		let process = VStack {
			if titleAlignment == .aboveProcess {
				title
			}
			text
		}
		
		switch layout {
		case .noImage:
			VStack {
				titleIfOnTop
				
				HStack {
					text
					process
				}
			}
		case .imageOnTop:
			VStack {
				photo
				
				titleIfOnTop
				
				HStack {
					text
					process
				}
			}
		case .imageAboveIngredients:
			VStack {
				titleIfOnTop
				
				HStack {
					VStack {
						photo
						text
					}
					
					process
				}
			}
		case .imageAboveProcess:
			VStack {
				titleIfOnTop
				
				HStack {
					text
					
					VStack {
						photo
						process
					}
				}
			}
		case .imageAboveBoth:
			VStack {
				titleIfOnTop
				
				photo
				
				HStack {
					text
					process
				}
			}
		}
	}
}

private func layoutPreview(titleAlignment: TitleAlignment) -> some View {
	VStack {
		ForEach(ImageLayout.allCases, id: \.self) {
			ImageLayoutButton(
				currentLayout: .constant(.imageAboveIngredients),
				layout: $0,
				titleAlignment: titleAlignment
			)
		}
	}
}

#Preview(traits: .sizeThatFitsLayout) {
	HStack {
		layoutPreview(titleAlignment: .centered)
		layoutPreview(titleAlignment: .aboveProcess)
	}
	.padding()
}
