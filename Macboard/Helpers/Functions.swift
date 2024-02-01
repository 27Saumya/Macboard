import SwiftUI
import Cocoa

func dataToImage(_ value: Data) -> (Image, String) {
    let image = NSImage(data: value) ?? NSImage()
    return (Image(nsImage: image), image.name() ?? "image.png")
}
