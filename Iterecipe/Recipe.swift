import Foundation

struct Recipe: Codable {
	var title = "Untitled Recipe"
	var source = ""
	var image: RecipeImage?
	
	var revisions: [Revision] = [.init()]
	var notes: [Note] = []
	
	struct Revision: Codable {
		var id = ObjectID<Self>()
		var dateCreated = Date()
		var ingredients: [Ingredient] = []
		var steps: [Step] = []
	}
}

struct Step: Codable, Identifiable {
	var id = ObjectID<Self>()
	var description = ""
}

extension Step: ExpressibleByStringLiteral {
	init(stringLiteral value: StringLiteralType) {
		self.init(description: value)
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

struct Ingredient: Codable, Identifiable {
	var id = ObjectID<Self>()
	var item = ""
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
					Ingredient(item: "42 g sugar"),
					Ingredient(item: "0.5 tsp salt"),
					Ingredient(item: "freshly-ground black pepper"),
					Ingredient(item: "freshly-ground black pepper again but this time it's much longer"),
					Ingredient(item: "250 mL milk"),
					Ingredient(item: "3 eggs"),
					Ingredient(item: "1 stick butter, melted, browned to a dark amber color"),
				],
				steps: [
					"The first step.",
					"The second step: please do this too.",
					"The third step, which is a lot longer than the other steps we've seen so far.",
					"The fourth step.",
					"One final step to finish it all up and get it out there after all this work to wrap to a new line.",
				]
			)
		],
		notes: ["a note", "another note that is considerably longer and thus takes multiple lines to display"]
	)
}
