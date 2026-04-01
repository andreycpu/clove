import Foundation
import AppKit

enum ItemType: String, Codable {
    case text
    case image
    case file
}

struct KnapsackItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: ItemType
    let content: String       // text content OR file path
    let thumbnailData: Data?  // compressed JPEG thumbnail, max 80x80
    let timestamp: Date
    let displayName: String

    var thumbnail: NSImage? {
        thumbnailData.flatMap { NSImage(data: $0) }
    }

    static func == (lhs: KnapsackItem, rhs: KnapsackItem) -> Bool {
        lhs.id == rhs.id
    }
}
