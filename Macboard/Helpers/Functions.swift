import Foundation
import SwiftUI
import Cocoa
import LinkPresentation

func dataToImage(_ value: Data) -> (Image, String) {
    let image = NSImage(data: value) ?? NSImage()
    return (Image(nsImage: image), image.name() ?? "image.png")
}
