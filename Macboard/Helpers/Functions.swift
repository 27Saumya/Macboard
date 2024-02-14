import SwiftUI
import Cocoa

func dataToImage(_ value: Data) -> (Image, String) {
    let image = NSImage(data: value) ?? NSImage()
    return (Image(nsImage: image), image.name() ?? "image.png")
}

func copyItem(_ item: ClipboardItem) {
    NSPasteboard.general.clearContents()
    if item.contentType == "Image" {
        NSPasteboard.general.setData(item.imageData!, forType: .tiff)
    } else {
        NSPasteboard.general.setString(item.content!, forType: .string)
    }
}
