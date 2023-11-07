import SwiftUI

struct LayoutedRecipe: View {
	var recipe: Recipe
	var revision: Recipe.Revision
	var layout: PrintLayout
	
	@Namespace var geometryNamespace
	
	var body: some View {
		VStack(spacing: 20) {
			if layout.imageLayout == .imageOnTop {
				image()
			}
			
			switch layout.titleAlignment {
			case .leading:
				title(alignment: .leading)
			case .centered:
				title(alignment: .center)
			case .aboveProcess:
				EmptyView()
			}
			
			if layout.imageLayout == .imageAboveBoth {
				image()
			}
			
			HStack(alignment: .top, spacing: 20) {
				VStack(spacing: 20) {
					if layout.imageLayout == .imageAboveIngredients {
						image()
					}
					
					textLines(for: revision.ingredients)
						.font(.callout.monospacedDigit().weight(.medium))
				}
				.frame(width: layout.ingredientsWidth)
				
				VStack(spacing: 20) {
					if layout.imageLayout == .imageAboveProcess {
						image()
					}
					
					if layout.titleAlignment == .aboveProcess {
						title(alignment: .leading)
					}
					
					textLines(for: revision.steps)
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(40)
		.environment(\.colorScheme, .light)
		.frame(width: layout.scaledWidth, height: layout.scaledHeight)
	}
	
	func title(alignment: Alignment) -> some View {
		VStack(spacing: 0) {
			Text(recipe.title)
				.font(.title.bold())
				.frame(maxWidth: .infinity, alignment: alignment)
			
			if !recipe.source.isEmpty {
				Text(recipe.source)
					.font(.footnote)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, alignment: alignment)
			}
		}
		.multilineTextAlignment(alignment == .center ? .center : .leading)
		.matchedGeometryEffect(id: "title", in: geometryNamespace)
	}
	
	func image() -> some View {
		recipe.image?.image
			.resizable()
			.scaledToFit()
			.clipShape(RoundedRectangle(cornerRadius: 20))
			.matchedGeometryEffect(id: "image", in: geometryNamespace)
			.zIndex(1)
	}
	
	func textLines(for items: [TextItem]) -> some View {
		VStack(spacing: 8) {
			ForEach(items) { Text($0.text) }
				.frame(maxWidth: .infinity, alignment: .leading)
				.fixedSize(horizontal: false, vertical: true)
		}
	}
}

// after all, why not?
// why shouldn't a view be transferable? ¯\_(ツ)_/¯
extension LayoutedRecipe: Transferable {
	static var transferRepresentation: some TransferRepresentation {
		DataRepresentation(exportedContentType: .pdf) { view in
			await view.renderPDF()
		}
		.suggestedFileName { $0.recipe.title }
	}
	
	@MainActor
	func renderPDF() -> Data {
		let data = NSMutableData()
		let consumer = CGDataConsumer(data: data)!
		let renderer = ImageRenderer(content: self)
		renderer.proposedSize = .init(width: layout.scaledWidth, height: layout.scaledHeight)
		renderer.render { size, render in
			var mediaBox = CGRect(origin: .zero, size: size)
			guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }
			context.beginPDFPage(nil)
			render(context)
			context.endPDFPage()
			context.closePDF()
		}
		return data as Data
	}
}
