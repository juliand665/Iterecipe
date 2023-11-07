import SwiftUI
import UniformTypeIdentifiers
import HandyOperators

struct IterecipeDocument {
	var recipe: Recipe?
	var loadingError: (any Error)?
}

extension IterecipeDocument: FileDocument {
	static var readableContentTypes: [UTType] { [.iterecipe] }
	
	private static let decoder = PropertyListDecoder()
	private static let encoder = PropertyListEncoder()
	
	init(configuration: ReadConfiguration) throws {
		do {
			let data = try configuration.file.regularFileContents
			??? CocoaError(.fileReadCorruptFile)
			
			let versionInfo = try Self.decoder.decode(Metadata.self, from: data)
			switch versionInfo.version {
			case 0:
				recipe = try Self.decoder.decode(Contents.self, from: data).recipe
			case let version:
				throw ReadError.unsupportedVersion(version)
			}
		} catch {
			print("Error loading document:", error)
			dump(error)
			// can't throw this error because then it just silently does nothing
			loadingError = error
		}
	}
	
	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		if let loadingError { throw WriteError.loadFailed(loadingError) }
		return .init(regularFileWithContents: try Self.encoder.encode(
			ContentsWithMetadata(version: 0, recipe: recipe!)
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
	
	enum WriteError: Error {
		case loadFailed(Error)
	}
}

extension UTType {
	static let iterecipe = UTType(exportedAs: "com.juliand665.iterecipe")
}
