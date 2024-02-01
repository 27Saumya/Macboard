import SwiftUI
import Cocoa
import Combine

extension View {
    func toast(isShowing: Binding<Bool>, message: String, position: CGPoint) -> some View {
        ZStack {
            self

            if isShowing.wrappedValue {
                ToastView(message: message)
                    .transition(.opacity)
                    .onAppear {
                        withAnimation(.default) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isShowing.wrappedValue = false
                            }
                        }
                    }
            }
        }
    }
}

extension View {
    func validKeyboardShortcut(number: Int, modifiers: EventModifiers) -> some View {
        ZStack {
            self
            
            if number < 9 {
                let key = KeyEquivalent(Character(UnicodeScalar("\(number+1)".replacingOccurrences(of: "0", with: ""))!))
                self.keyboardShortcut(key , modifiers: modifiers)
            }
        }
    }
}

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
