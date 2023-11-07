import SwiftUI
import UserDefault
#if os(macOS)
import PDFKit
#endif

@MainActor
struct ExportDesigner: View {
	var recipe: Recipe
	var revision: Recipe.Revision
	
	// TODO: maybe a presets system?
	@UserDefault.State("ExportDesigner.layout") var layout: PrintLayout = .init()
	
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	
	var body: some View {
		GeometryReader { geometry in
			let aspectRatio = geometry.size.width / geometry.size.height
			let isWide = aspectRatio > 0.8
			let layout = isWide
			? AnyLayout(HStackLayout(spacing: 0))
			: AnyLayout(VStackLayout(spacing: 0))
			layout {
				printPreview()
					.padding(20)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
#if !os(macOS)
					.background(Color(.systemGroupedBackground))
#endif
					.frame(minWidth: isWide ? min(200, 0.3 * geometry.size.width) : nil)
					.frame(minHeight: isWide ? nil : min(200, 0.3 * geometry.size.width))
					.overlay(alignment: .bottomTrailing) {
						exportControls().padding()
					}
				
				Divider()
				
				LayoutCustomizer(layout: $layout)
					.frame(width: isWide ? min(400, 0.7 * geometry.size.width) : nil)
					.frame(height: isWide ? nil : min(400, 0.7 * geometry.size.height))
#if os(macOS)
					.padding()
#endif
			}
#if !os(macOS)
			.toolbarBackground(isWide ? .visible : .automatic, for: .navigationBar)
#endif
		}
		.navigationTitle("Customize Export")
#if os(macOS)
		.frame(minWidth: 400, idealWidth: 800, minHeight: 300, idealHeight: 600)
#else
		.navigationBarTitleDisplayMode(.inline)
#endif
	}
	
	func exportControls() -> some View {
		VStack {
			Button("Print", systemImage: "printer") {
				let pdf = printableView().renderPDF()
#if !os(macOS)
				UIPrintInteractionController.shared.printingItem = pdf
				UIPrintInteractionController.shared.present(animated: true)
#else
				// FIXME: this currently crashes for some reason
				let document = PDFDocument(data: pdf)!
				let operation = document.printOperation(for: nil, scalingMode: .pageScaleToFit, autoRotate: false)!
				operation.view!.frame = .init(x: 0, y: 0, width: 800, height: 600)
				operation.run()
#endif
			}
			
			ShareLink(item: printableView(), preview: .init(recipe.title))
		}
		.labelStyle(.iconOnly)
		.buttonStyle(.circular(padding: 4, isProminent: true))
	}
	
	func printPreview() -> some View {
		GeometryReader { geometry in
			printableView()
				.background(.white)
				.scaleEffect(geometry.size.width / layout.scaledWidth, anchor: .topLeading)
		}
		.aspectRatio(layout.pageSize.aspectRatio, contentMode: .fit)
		.clipShape(RoundedRectangle(cornerRadius: 16))
		.shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 12)
		.zIndex(1)
	}
	
	func printableView() -> LayoutedRecipe {
		LayoutedRecipe(recipe: recipe, revision: revision, layout: layout)
	}
}

extension PrintLayout: DefaultsValueConvertible {}

#Preview {
	NavigationStack {
		ExportDesigner(recipe: .example, revision: Recipe.example.revisions.last!)
	}
}
