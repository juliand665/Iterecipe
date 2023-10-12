import SwiftUI
import UniformTypeIdentifiers
import HandyOperators

struct IterecipeDocument: Codable {
	var recipe = Recipe()
}

extension IterecipeDocument: FileDocument {
	static var readableContentTypes: [UTType] { [.iterecipe] }
	
	private static let decoder = PropertyListDecoder()
	private static let encoder = PropertyListEncoder()
	
	init(configuration: ReadConfiguration) throws {
		let data = try configuration.file.regularFileContents
		??? CocoaError(.fileReadCorruptFile)
		
		let versionInfo = try Self.decoder.decode(Metadata.self, from: data)
		switch versionInfo.version {
		case 0:
			recipe = try Self.decoder.decode(Contents.self, from: data).recipe
		case let version:
			throw ReadError.unsupportedVersion(version)
		}
	}
	
	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		.init(regularFileWithContents: try Self.encoder.encode(
			ContentsWithMetadata(version: 0, recipe: recipe)
		)) <- {
			$0.preferredFilename = "Recipe.iterecipe"
		}
	}
	
	private struct Metadata: Codable {
		var version: Int
	}
	
	private struct Contents: Codable {
		var recipe: Recipe
	}
	
	private struct ContentsWithMetadata: Encodable {
		var version: Int
		var recipe: Recipe
	}
	
	enum ReadError: Error {
		case unsupportedVersion(Int)
	}
}

extension UTType {
	static let iterecipe = UTType(exportedAs: "com.juliand665.iterecipe")
}
