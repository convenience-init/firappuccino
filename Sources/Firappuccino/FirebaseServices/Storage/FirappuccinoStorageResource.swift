import Foundation

public typealias ResourceID = DocumentID
public typealias ResourcePath = String

/**
 Provides information about an uploadable resource.
 
 Use this class with ``FirappuccinoResourceStore``!
 
 A `FirappuccinoStorageResource` contains the logic to "package" resources to be "attached" to a `FirappuccinoDocument` and uploaded to Firebase Storage, but are not intended to be uploaded themselves.
 */
public class FirappuccinoStorageResource: FirappuccinoDocumentModel {
	
	/// The url of the resource.
	public var url: URL?
	
	/// The id of the resource.
	public var id: ResourceID = UUID().uuidStringSansDashes
	
	/// The resource's content type.
	public var kind: Kind = .png
	
	/// A folder to place the image in.
	public var folder: String?
	
	/// The reference path of the resource.
	public var path: ResourcePath {
		
		if let folder = folder {
			return "\(kind.category())s/\(folder)/\(id).\(kind.rawValue)"
		}
		else {
			return "\(kind.category())s/\(id).\(kind.rawValue)"
		}
	}
	
	public init(id: String) {
		self.id = id
	}
	
	public init(id: String, folder: String?) {
		self.id = id
		self.folder = folder
	}
	
	/**
	 The kind of resource being dealt with.
	 
	 - important:  currently, .png image files are the only supported resources.
	 */
	public enum Kind: String, Codable {
		
		case png
		
		public func category() -> String {
			switch self {
				case .png: return "image"
			}
		}
		
		public func contentType() -> String {
			return "\(category())/\(self.rawValue)"
		}
	}
	
	
	/// Adds an .png resource "attachment" to a `FirappuccinoDocument`
	/// - Parameters:
	///   - document: The `FirappuccinoDocument` to attach the .png file to
	///   - data: The .png imageData
	///   - andPath: The `CollectionName` to upload the attachment to
	///   - progress: The progress of the `FIRUploadTask`
	/// - Returns: An optional valid `URL` if successful
	/// - Throws: An `NSError`
	public static func attachImageResource<T>(to document: T, using data: Data, andPath: String, progress: @escaping (Double) -> Void = { _ in }) async throws -> URL? where T: FirappuccinoDocument {
		
		let document = document
		do {
			async let resourceURL = await FirappuccinoResourceStore.put(data, to: FirappuccinoStorageResource(id: document.id, folder: andPath), progress: progress)
			try await document.set()
			return await resourceURL
		}
		catch let error as NSError {
			Firappuccino.logger.error("\(error.localizedDescription)")
			throw error
		}
	}
}
