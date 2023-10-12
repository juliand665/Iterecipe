import Foundation
import HandyOperators

struct Recipe: Codable {
	var title = ""
	var source = ""
	var image: RecipeImage?
	
	var revisions: [Revision] = [.init()]
	
	mutating func addRevision() {
		revisions.append(revisions.last! <- { $0.notes = [] })
	}
	
	struct Revision: Codable {
		var id = ObjectID<Self>()
		var dateCreated = Date()
		var ingredients: [TextItem] = []
		var steps: [TextItem] = []
		var notes: [Note] = []
	}
}

struct TextItem: Codable, Identifiable {
	var id = ObjectID<Self>()
	var text = ""
}

extension TextItem: ExpressibleByStringLiteral {
	init(stringLiteral value: StringLiteralType) {
		self.init(text: value)
	}
}

struct Note: Codable, Identifiable {
	var id = ObjectID<Self>()
	var dateCreated = Date()
	var contents = ""
}

extension Note: ExpressibleByStringLiteral {
	init(stringLiteral value: StringLiteralType) {
		self.init(contents: value)
	}
}

struct ObjectID<Object>: Hashable, Codable {
	let rawValue: UUID
	
	init() {
		rawValue = .init()
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.rawValue = try container.decode(UUID.self)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}
}

extension Recipe {
	static let example = Self(
		title: "Example Recipe",
		source: "www.example.com/recipes/example",
		image: nil,
		revisions: [
			.init(
				ingredients: [
					"42 g sugar",
					"0.5 tsp salt",
					"freshly-ground black pepper",
					"freshly-ground black pepper again but this time it's much longer",
					"250 mL milk",
					"3 eggs",
					"1 stick butter, melted, browned to a dark amber color",
				],
				steps: [
					"The first step.",
					"The second step: please do this too.",
					"The third step, which is a lot longer than the other steps we've seen so far.",
					"The fourth step.",
					"One final step to finish it all up and get it out there after all this work to wrap to a new line.",
				],
				notes: ["a note", "another note that is considerably longer and thus takes multiple lines to display"]
			)
		]
	)
}
