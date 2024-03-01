import SwiftUI
import Cocoa
import KeyboardShortcuts
import Carbon
import Sauce

extension KeyboardShortcuts.Name {
    static let toggleMacboard = Self("toggleMacboard", default: .init(.v, modifiers: [.shift, .command]))
    static let clearClipboard = Self("clearClipboard", default: .init(.delete, modifiers: [.command]))
    static let copyAndHide = Self("copyAndHide", default: .init(.return, modifiers: []))
    static let copyItem = Self("copyItem", default: .init(.return, modifiers: [.command]))
    static let togglePin = Self("togglePin", default: .init(.p, modifiers: [.command]))
    static let deleteItem = Self("deleteItem", default: .init(.delete, modifiers: []))
}
