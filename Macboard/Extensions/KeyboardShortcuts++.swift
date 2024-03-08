import SwiftUI
import Cocoa
import KeyboardShortcuts
import Carbon
import Sauce

extension KeyboardShortcuts.Name {
    static let toggleMacboard = Self("toggleMacboard", default: .init(.v, modifiers: [.shift, .command]))
    static let clearClipboard = Self("clearClipboard", default: .init(.delete, modifiers: [.command]))
    static let paste = Self("paste", default: .init(.return, modifiers: []))
    static let copyAndHide = Self("copyAndHide", default: .init(.return, modifiers: [.option]))
    static let togglePin = Self("togglePin", default: .init(.p, modifiers: [.command]))
    static let deleteItem = Self("deleteItem", default: .init(.delete, modifiers: []))
}
