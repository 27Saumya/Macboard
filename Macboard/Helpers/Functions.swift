import SwiftUI
import Cocoa
import KeyboardShortcuts
import Sauce

func dataToImage(_ value: Data) -> (Image, String) {
    let image = NSImage(data: value) ?? NSImage()
    return (Image(nsImage: image), image.name() ?? "Image")
}

func copyToClipboard(_ item: ClipboardItem) {
    NSPasteboard.general.clearContents()
    if item.contentType == "Image" {
        NSPasteboard.general.setData(item.imageData!, forType: .tiff)
    } else {
        NSPasteboard.general.setString(item.content!, forType: .string)
    }
}

func shortcutToText(_ shortcut: KeyboardShortcuts.Shortcut) -> String {
    var description = ""
    let modifierFlags = shortcut.modifiers
    if modifierFlags.contains(.command) {
        description += "⌘ "
    }
    
    if modifierFlags.contains(.shift) {
        description += "⇧ "
    }
    
    if modifierFlags.contains(.option) {
        description += "⌥ "
    }
    
    if modifierFlags.contains(.control) {
        description += "⌃ "
    }
    
    if modifierFlags.contains(.capsLock) {
        description += "⇪ "
    }
    
    if modifierFlags.contains(.numericPad) {
        description += "⇒ "
    }
    if let char = Sauce.shared.character(for: shortcut.carbonKeyCode, carbonModifiers: shortcut.carbonModifiers) {
        description += char.uppercased()
    }
    return description
}
