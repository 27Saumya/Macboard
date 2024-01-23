import Foundation
import SwiftUI
import SwiftData


@Model
class ClipboardItem: Identifiable {
    let id: String
    let content: String?
    let imageData: Data?
    var isFavourite: Bool = false
    var contentType: ContentType
    
    init(content: String? = nil, imageData: Data? = nil, isFavourite: Bool = false, contentType: ContentType = .text) {
        let id = UUID().uuidString
        self.id = id
        self.content = content
        self.imageData = imageData
        self.isFavourite = isFavourite
        self.contentType = contentType
    }
}
