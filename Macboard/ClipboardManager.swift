import Foundation
import Cocoa

class ClipboardManagerViewModel: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []

    private var clipboardChangeTimer: Timer?

    init() {
        clipboardChangeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }

        checkClipboard()
    }

    deinit {
        clipboardChangeTimer?.invalidate()
    }

    private func checkClipboard() {
        if self.clipboardContentType().0 == .text {
            guard let content = NSPasteboard.general.string(forType: .string), !content.isEmpty else { return }
            
            if !content.isEmpty {
                if clipboardItems.firstIndex(where: {
                    if $0.contentType == .text {
                        return $0.content! == content
                    } else {
                        return false
                    }
                }) == nil {
                    let newItem = ClipboardItem(content: content, contentType: .text)
                    clipboardItems.insert(newItem, at: 0)
                }
            }
        } else {
            guard let imageData = NSPasteboard.general.data(forType: self.clipboardContentType().1!) else { return }
            
            if !imageData.isEmpty {
                if clipboardItems.firstIndex(where: {
                    if $0.contentType == .image {
                        return $0.imageData! == imageData
                    } else {
                        return false
                    }
                }) == nil {
                    let newItem = ClipboardItem(imageData: imageData, contentType: .image)
                    clipboardItems.insert(newItem, at: 0)
                }
            }
        }
        
        clipboardItems = clipboardItems.sorted(by: { item1, item2 in
            item1.isFavourite && !item2.isFavourite
        })
    }
    
    private func clipboardContentType() -> (ContentType, NSPasteboard.PasteboardType?) {
        let image_types: [NSPasteboard.PasteboardType] = [.png, .tiff]
        let _type = NSPasteboard.general.types?.first
        if image_types.contains(_type!) {
            return (.image, _type!)
        } else {
            return (.text, nil)
        }
    }

    func clearClipboard() {
        clipboardItems.removeAll()
    }

    func removeClipboardItem(at index: Int) {
        guard index >= 0, index < clipboardItems.count else { return }
        clipboardItems.remove(at: index)
    }

    func toggleFavourite(for item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems[index].isFavourite.toggle()
        }
    }
}



