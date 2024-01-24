import Foundation
import SwiftUI
import Cocoa

extension Bool: Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        !lhs && rhs
    }
}


extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            return match.range.length == self.utf16.count
        } else {
            return false
        }
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
