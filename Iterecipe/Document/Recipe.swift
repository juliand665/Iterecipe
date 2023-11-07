import SwiftUI
import ArrayBuilder
import HandyOperators

struct Recipe: Codable {
	var title = ""
	var source = ""
	var image: RecipeImage?
	
	var revisions: [Revision] = [.init()]
	
	mutating func addRevision() {
		let current = revisions.last!
		revisions.append(.init(ingredients: current.ingredients, steps: current.steps))
	}
	
	struct Revision: Codable, Identifiable {
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
		source: "example.com/recipes/example",
		image: .example,
		revisions: .init {
			let initial = Revision(
				dateCreated: .init(timeIntervalSinceNow: -100_000),
				ingredients: [
					"42 g sugar",
					"0.5 tsp salt",
					"just some black pepper",
					"freshly-ground black pepper again but this time it's much longer",
					"2 eggs",
					"1 stick butter, melted",
				],
				steps: [
					"The first step.",
					"The second step: please do this too.",
					"The third step, which is a lot longer than the other steps we've seen so far.",
					"The fourth step.",
					"One final step to finish it all up and get it out there after all this work to wrap to a new line.",
					"Actually I felt like another step because this process was proportionally much shorter than it would usually be.",
					"Bon appétit!",
				],
				notes: ["an old note"]
			)
			
			initial
			
			Revision(dateCreated: .init(timeIntervalSinceNow: -20_000), ingredients: initial.ingredients, steps: initial.steps)
			
			Revision(ingredients: initial.ingredients, steps: initial.steps) <- {
				$0.ingredients.remove(at: 3)
				$0.ingredients.insert("250 mL milk", at: 2)
				$0.ingredients[3].text = "freshly-ground black pepper"
				$0.ingredients[5].text = "1 stick butter, melted, browned to a dark amber color"
				$0.ingredients.move(fromOffsets: [3, 4], toOffset: 0)
				
				$0.steps.insert("Actually i forgot something important!", at: 2)
				$0.steps[5].text += " This is the best part."
				
				$0.notes = [
					"a note",
					"another note that is considerably longer and thus takes multiple lines to display"
				]
			}
		}
	)
}

extension RecipeImage {
#if os(macOS)
	static let example: Self? = nil
#else
	static let example = try? Self(
		imageData: #imageLiteral(resourceName: "chocolate ice cream").heicData()!
	)
#endif
}

#Preview {
	RecipeImage.example?.image.resizable().scaledToFit()
}
