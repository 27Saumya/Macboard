import Foundation
import SwiftUI
import Cocoa

struct LinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onHover { isHovered in
                NSCursor.pointingHand.set()
            }
    }
}


struct ToastView: View {
    var message: String

    @State private var opacity: Double = 1

    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                .opacity(opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            opacity = 0
                        }
                    }
                }
        }
    }
}
