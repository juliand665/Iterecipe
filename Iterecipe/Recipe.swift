import Foundation
import ImageIO
import HandyOperators
import UniformTypeIdentifiers

struct Recipe: Codable {
	var title = "Untitled Recipe"
	var source = ""
	
	var ingredients: [Ingredient] = []
	var steps: [Step] = []
	var notes: [Note] = []
	
	var image: RecipeImage?
}

struct Step: Codable, Identifiable {
	let id = UUID()
	
	var description = ""
	
	private enum CodingKeys: String, CodingKey {
		case description
	}
}

extension Step: ExpressibleByStringLiteral {
	init(stringLiteral value: StringLiteralType) {
		self.init(description: value)
	}
}

struct Note: Codable, Identifiable {
	let id = UUID()
	
	var contents = "" {
		didSet { dateModified = .now }
	}
	var dateCreated = Date()
	var dateModified = Date()
	
	private enum CodingKeys: String, CodingKey {
		case contents
		case dateCreated
		case dateModified
	}
}

extension Note: ExpressibleByStringLiteral {
	init(stringLiteral value: StringLiteralType) {
		self.init(contents: value)
	}
}

struct Ingredient: Codable, Identifiable {
	let id = UUID()
	
	var quantity: Quantity?
	var item = ""
	
	private enum CodingKeys: String, CodingKey {
		case quantity
		case item
	}
	
	struct Quantity: Codable {
		var amount: Double?
		var unit: Unit?
	}
	
	enum Unit: Codable, Hashable {
		case grams
		case milliliters
		case teaspoons
		case tablespoons
		case custom(String)
	}
}

struct RecipeImage: Codable {
	var cgImage: CGImage
	
	public init(from decoder: Decoder) throws {
		let data = try decoder.singleValueContainer().decode(Data.self)
		cgImage = .fromPNGData(data)!
	}
	
	public func encode(to encoder: Encoder) throws {
		try encoder.singleValueContainer() <- {
			try $0.encode(cgImage.pngData())
		}
	}
}

private extension CGImage {
	static func fromPNGData(_ data: Data) -> Self? {
		Self(
			pngDataProviderSource: CGDataProvider(data: data as CFData)!,
			decode: nil,
			shouldInterpolate: false,
			intent: .defaultIntent
		)
	}
	
	func pngData() -> Data {
		(CFDataCreateMutable(nil, 0)! <- {
			let destination = CGImageDestinationCreateWithData(
				$0,
				UTType.png.identifier as CFString,
				1, // 1 image
				nil // no options
			)!
			CGImageDestinationAddImage(destination, self, nil)
			let didSucceed = CGImageDestinationFinalize(destination)
			assert(didSucceed)
		}) as Data
	}
}

extension Recipe {
	static let example = Self(
		title: "Example Recipe",
		source: "www.example.com/recipes/example",
		ingredients: [
			Ingredient(quantity: .init(amount: 42, unit: .grams), item: "sugar"),
			Ingredient(quantity: .init(amount: 0.5, unit: .teaspoons), item: "salt"),
			Ingredient(item: "freshly-ground black pepper"),
			Ingredient(item: "freshly-ground black pepper again but this time it's much longer"),
			Ingredient(quantity: .init(amount: 250, unit: .milliliters), item: "milk"),
			Ingredient(quantity: .init(amount: 3), item: "eggs"),
			Ingredient(quantity: .init(amount: 1, unit: .custom("stick")), item: "butter, melted, browned to a dark amber color"),
		],
		steps: [
			"The first step.",
			"The second step: please do this too.",
			"The third step, which is a lot longer than the other steps we've seen so far.",
			"The fourth step.",
			"One final step to finish it all up and get it out there after all this work to wrap to a new line.",
		],
		notes: ["a note", "another note"],
		image: nil
	)
}
