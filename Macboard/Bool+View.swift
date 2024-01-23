import Foundation
import SwiftUI
import Cocoa

extension Bool: Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        !lhs && rhs
    }
}


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
