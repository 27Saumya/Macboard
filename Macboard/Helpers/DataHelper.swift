import Foundation
import SwiftUI
import SwiftData


enum ContentType: Codable {
    case text
    case image
}

@Model
class ClipboardItem: Identifiable {
    let id: String
    var createdAt: Date
    let content: String?
    let imageData: Data?
    var isFavourite: Bool = false
    var contentType: ContentType
    
    init(content: String? = nil, imageData: Data? = nil, isFavourite: Bool = false, contentType: ContentType = .text) {
        let id = UUID().uuidString
        self.id = id
        let createdAt = Date.now
        self.createdAt = createdAt
        self.content = content
        self.imageData = imageData
        self.isFavourite = isFavourite
        self.contentType = contentType
    }
}

struct Metadata {
    let key: String
    let value: String
}
