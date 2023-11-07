import SwiftUI

struct PrintLayout: Equatable, Codable {
	var pageSize: PageSize = .localeDefault
	var scaleFactor = 4.0
	var ingredientsWidth = 250.0
	var titleAlignment: TitleAlignment = .aboveProcess
	var imageLayout: ImageLayout = .imageAboveIngredients
	
	var scaledWidth: Double {
		pageSize.width * scaleFactor
	}
	
	var scaledHeight: Double {
		pageSize.height * scaleFactor
	}
}

struct PageSize: Equatable, Codable {
	private static let usLetterRegions: Set<Locale.Region> = [
		.unitedStates, .canada, .chile, .colombia, .costaRica, .mexico, .panama, .guatemala, .dominicanRepublic, .philippines,
	]
	
	static let dinA4 = PageSize(width: 210, height: 297)
	static let usLetter = PageSize(width: 215.9, height: 279.4)
	
	static let localeDefault = Locale.current.region.map(usLetterRegions.contains) == true ? usLetter : dinA4
	
	var width, height: Double // mm
	
	var size: CGSize { .init(width: width, height: height) }
	var aspectRatio: Double { width / height }
}

enum TitleAlignment: Equatable, Codable, CaseIterable {
	case leading
	case centered
	case aboveProcess
	
	var label: LocalizedStringKey {
		switch self {
		case .leading:
			"Left Edge"
		case .centered:
			"Centered"
		case .aboveProcess:
			"Above Process"
		}
	}
}

enum ImageLayout: Equatable, Codable, CaseIterable {
	case noImage
	case imageOnTop
	case imageAboveIngredients
	case imageAboveProcess
	case imageAboveBoth
	
	var label: LocalizedStringKey {
		switch self {
		case .noImage:
			"No Image"
		case .imageOnTop:
			"Image on Top"
		case .imageAboveIngredients:
			"Image above Ingredients"
		case .imageAboveProcess:
			"Image above Process"
		case .imageAboveBoth:
			"Image below Title"
		}
	}
}
