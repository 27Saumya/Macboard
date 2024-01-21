import Foundation
import SwiftUI


struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: String
    var isFavourite: Bool = false
    
    init(content: String, isFavourite: Bool = false) {
            self.content = content
            self.isFavourite = isFavourite
        }
}


struct ClipboardItemListView: View {
    @ObservedObject var viewModel: ClipboardManagerViewModel

    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastPosition: CGPoint = .zero

    var body: some View {
        List {
            ForEach(viewModel.clipboardItems) { item in
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Spacer()

                            Button(action: {
                                withAnimation {
                                    let buttonFrame = NSApplication.shared.keyWindow?.contentView?.convert(NSRect(x: 0, y: 0, width: 50, height: 30), to: nil) ?? NSRect(x: 0, y: 0, width: 50, height: 30)
                                    viewModel.toggleFavourite(for: item)
                                    showToast(message: item.isFavourite ? "Added to Favorites" : "Removed from Favorites", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                                }
                            }) {
                                Image(systemName: item.isFavourite ? "star.fill" : "star")
                            }
                            .buttonStyle(LinkButtonStyle())

                            Button(action: {
                                let buttonFrame = NSApplication.shared.keyWindow?.contentView?.convert(NSRect(x: 0, y: 0, width: 50, height: 30), to: nil) ?? NSRect(x: 0, y: 0, width: 50, height: 30)
                                withAnimation {
                                    viewModel.removeClipboardItem(at: viewModel.clipboardItems.firstIndex(where: { $0.id == item.id })!)
                                    showToast(message: "Removed from Clipboard", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(LinkButtonStyle())

                            Button(action: {
                                let buttonFrame = NSApplication.shared.keyWindow?.contentView?.convert(NSRect(x: 0, y: 0, width: 50, height: 30), to: nil) ?? NSRect(x: 0, y: 0, width: 50, height: 30)
                                withAnimation {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(item.content, forType: .string)
                                    showToast(message: "Copied to Clipboard", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(LinkButtonStyle())
                        }
                        .padding()

                        Text(item.content)
                            .padding(.leading, 12)
                            .padding(.trailing, 12)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
        }
        .toast(isShowing: $showToast, message: toastMessage, position: toastPosition)
    }

    private func showToast(message: String, position: CGPoint) {
        toastMessage = message
        toastPosition = position
        showToast.toggle()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast.toggle()
        }
    }
}


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







