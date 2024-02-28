import SwiftUI
import Cocoa
import Combine
import KeyboardShortcuts
import Carbon

public struct ChangeObserver<V: Equatable>: ViewModifier {
    public init(newValue: V, action: @escaping (V) -> Void) {
        self.newValue = newValue
        self.newAction = action
    }

    private typealias Action = (V) -> Void

    private let newValue: V
    private let newAction: Action

    @State private var state: (V, Action)?

    public func body(content: Content) -> some View {
        if #available(macOS 14, *) {
            assertionFailure("Please don't use this ViewModifer directly and use the `onChange(of:perform:)` modifier instead.")
        }
        return content
            .onAppear()
            .onReceive(Just(newValue)) { newValue in
                if let (currentValue, action) = state, newValue != currentValue {
                    action(newValue)
                }
                state = (newValue, newAction)
            }
    }
}

extension View {
    @_disfavoredOverload
    @ViewBuilder public func onChange<V>(of value: V, perform action: @escaping (V) -> Void) -> some View where V: Equatable {
        if #available(macOS 14, *) {
            onChange(of: value, perform: action)
        } else {
            modifier(ChangeObserver(newValue: value, action: action))
        }
    }
}

extension View {
    public func onKeyboardShortcut(_ shortcut: KeyboardShortcuts.Name, perform: @escaping () -> ()) -> some View {
        ZStack {
            Button("") {
                perform()
            }
            .hidden()
            .keyboardShortcut(shortcut)
            
            self
        }
    }
}

extension View {
    
    public func keyboardShortcut(_ shortcut: KeyboardShortcuts.Name) -> some View {
        if let shortcut = shortcut.shortcut {
            if let keyEquivalent = shortcut.toKeyEquivalent() {
                return AnyView(self.keyboardShortcut(keyEquivalent, modifiers: shortcut.toEventModifiers()))
            }
        }
        
        return AnyView(self)
    }
    
}

extension KeyboardShortcuts.Shortcut {
    
    func toKeyEquivalent() -> KeyEquivalent? {
        let carbonKeyCode = UInt16(self.carbonKeyCode)
        let maxNameLength = 4
        var nameBuffer = [UniChar](repeating: 0, count : maxNameLength)
        var nameLength = 0
        
        let modifierKeys = UInt32(alphaLock >> 8) & 0xFF
        var deadKeys: UInt32 = 0
        let keyboardType = UInt32(LMGetKbdType())
        
        let source = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            NSLog("Could not get keyboard layout data")
            return nil
        }
        let layoutData = Unmanaged<CFData>.fromOpaque(ptr).takeUnretainedValue() as Data
        let osStatus = layoutData.withUnsafeBytes {
            UCKeyTranslate($0.bindMemory(to: UCKeyboardLayout.self).baseAddress, carbonKeyCode, UInt16(kUCKeyActionDown),
                           modifierKeys, keyboardType, UInt32(kUCKeyTranslateNoDeadKeysMask),
                           &deadKeys, maxNameLength, &nameLength, &nameBuffer)
        }
        guard osStatus == noErr else {
            NSLog("Code: 0x%04X  Status: %+i", carbonKeyCode, osStatus);
            return nil
        }
        
        return KeyEquivalent(Character(String(utf16CodeUnits: nameBuffer, count: nameLength)))
    }
    
    func toEventModifiers() -> SwiftUI.EventModifiers {
        var modifiers: SwiftUI.EventModifiers = []
        
        if self.modifiers.contains(NSEvent.ModifierFlags.command) {
            modifiers.update(with: EventModifiers.command)
        }
        
        if self.modifiers.contains(NSEvent.ModifierFlags.control) {
            modifiers.update(with: EventModifiers.control)
        }
        
        if self.modifiers.contains(NSEvent.ModifierFlags.option) {
            modifiers.update(with: EventModifiers.option)
        }
        
        if self.modifiers.contains(NSEvent.ModifierFlags.shift) {
            modifiers.update(with: EventModifiers.shift)
        }
        
        if self.modifiers.contains(NSEvent.ModifierFlags.capsLock) {
            modifiers.update(with: EventModifiers.capsLock)
        }
        
        if self.modifiers.contains(NSEvent.ModifierFlags.numericPad) {
            modifiers.update(with: EventModifiers.numericPad)
        }
        
        return modifiers
    }
    
}
