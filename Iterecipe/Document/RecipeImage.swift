import SwiftUI
import CoreImage
import CoreTransferable
import HandyOperators

struct RecipeImage: Codable {
	var imageData: Data
	var image: Image
	
	public init(imageData: Data) throws {
		self.imageData = imageData
		let source = try CGImageSourceCreateWithData(imageData as CFData, nil) ??? SerializationError.sourceCreationFailed
		let cgImage = try CGImageSourceCreateImageAtIndex(source, 0, nil) ??? SerializationError.sourceMissingImage
		let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?
		let orientation = (properties?[kCGImagePropertyOrientation] as? UInt32)
			.flatMap(CGImagePropertyOrientation.init(rawValue:)) ?? .up
		self.image = Image(cgImage, scale: 1, orientation: orientation.swiftUIOrientation, label: Text("Recipe Image"))
	}
	
	public init(from decoder: Decoder) throws {
		try self.init(imageData: decoder.singleValueContainer().decode(Data.self))
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

private extension CGImagePropertyOrientation {
	var swiftUIOrientation: Image.Orientation {
		switch self {
		case .up: .up
		case .upMirrored: .upMirrored
		case .down: .down
		case .downMirrored: .downMirrored
		case .left: .left
		case .leftMirrored: .leftMirrored
		case .right: .right
		case .rightMirrored: .rightMirrored
		}
	}
}

extension RecipeImage: Transferable {
	static var transferRepresentation: some TransferRepresentation {
		DataRepresentation(importedContentType: .image) { try Self(imageData: $0) }
	}
}
