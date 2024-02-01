import SwiftUI
import Cocoa

extension Bool: Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        !lhs && rhs
    }
}
