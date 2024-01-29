import Foundation
import SwiftUI
import Cocoa

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
