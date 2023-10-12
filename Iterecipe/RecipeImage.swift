import Foundation
import CoreImage
import UniformTypeIdentifiers
import HandyOperators

struct RecipeImage: Codable {
	var imageData: Data
	var cgImage: CGImage
	
	public init(_ cgImage: CGImage) throws {
		self.cgImage = cgImage
		
		// store as HEIF data
		let data = CFDataCreateMutable(nil, 0)! // no allocator, unlimited capacity
		let destination = try CGImageDestinationCreateWithData(data, UTType.heic.identifier as CFString, 1, nil) // 1 image, no options
		??? SerializationError.destinationCreationFailed
		CGImageDestinationAddImage(destination, cgImage, [
			kCGImageDestinationLossyCompressionQuality: 0.8,
			// TODO: this should also contain orientation information
		] as CFDictionary)
		guard CGImageDestinationFinalize(destination) else { throw SerializationError.finalizeFailed }
		self.imageData = data as Data
	}
	
	public init(from decoder: Decoder) throws {
		self.imageData = try decoder.singleValueContainer().decode(Data.self)
		let source = try CGImageSourceCreateWithData(imageData as CFData, nil) ??? SerializationError.sourceCreationFailed
		self.cgImage = try CGImageSourceCreateImageAtIndex(source, 0, nil) ??? SerializationError.sourceMissingImage
	}
	
	public func encode(to encoder: Encoder) throws {
		try encoder.singleValueContainer() <- {
			try $0.encode(imageData)
		}
	}
	
	enum SerializationError: Error {
		case sourceCreationFailed
		case sourceMissingImage
		case destinationCreationFailed
		case finalizeFailed
	}
}

private final class ImageDestination {
	let destination: CGImageDestination
	
	init?(data: CFMutableData, type: UTType, count: Int = 1, options: CFDictionary? = nil) {
		guard let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, count, options) else { return nil }
		self.destination = destination
	}
	
	func add(_ image: CGImage, properties: CFDictionary? = nil) {
		CGImageDestinationAddImage(destination, image, properties)
	}
	
	func finalize() throws {
		guard CGImageDestinationFinalize(destination) else {
			throw SaveError.finalizeFailed
		}
	}
	
	enum SaveError: Error {
		case finalizeFailed
	}
}
