import Foundation

struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: Date
    var isFavourite: Bool = false
}
