import Foundation
import SwiftUI
import SwiftData
import Cocoa


struct ClipboardItemListView: View {
    
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL
    
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastPosition: CGPoint = .zero
    
    @Query(sort: [SortDescriptor(\ClipboardItem.isFavourite, order: .reverse), SortDescriptor(\ClipboardItem.createdAt, order: .reverse)]) var clipboardItems: [ClipboardItem]
    
    @State private var clipboardChangeTimer: Timer?

    var body: some View {
        
        List {
            Section {
                ForEach(clipboardItems) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                if item.contentType == .text {
                                    if item.content!.isValidURL {
                                        Link(item.content!, destination: URL(string: item.content!)!)
                                    }
                                    else {
                                        Text(item.content!)
                                            .lineLimit(1)
                                    }
                                } else {
                                    let image = dataToImage(item.imageData!)
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .scaledToFit()
                                        .frame(width: 100, height: 50)
                                }
                                
                                Spacer()

                                Button(action: {
                                    withAnimation {
                                        let buttonFrame = NSApplication.shared.keyWindow?.contentView?.convert(NSRect(x: 0, y: 0, width: 50, height: 30), to: nil) ?? NSRect(x: 0, y: 0, width: 50, height: 30)
                                        toggleFavourite(context: context, for: item)
                                        showToast(message: item.isFavourite ? "Removed from Favourites" : "Added to Favourites", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                                    }
                                }) {
                                    Image(systemName: item.isFavourite ? "star.fill" : "star")
                                }
                                .buttonStyle(LinkButtonStyle())

                                Button(action: {
                                    let buttonFrame = NSApplication.shared.keyWindow?.contentView?.convert(NSRect(x: 0, y: 0, width: 50, height: 30), to: nil) ?? NSRect(x: 0, y: 0, width: 50, height: 30)
                                    withAnimation {
                                        removeClipboardItem(context: context, at: clipboardItems.firstIndex(where: { $0.id == item.id })!)
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
                                        if item.contentType == .image {
                                            NSPasteboard.general.setData(item.imageData!, forType: .tiff)
                                        } else {
                                            NSPasteboard.general.setString(item.content!, forType: .string)
                                        }
                                        showToast(message: "Copied to Clipboard", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                                    }
                                }) {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(LinkButtonStyle())
                            }
                        }
                    }
                
            } header: {
                HStack {
                    Text("Clipboard")
                    Spacer()
                    Button(action: {
                        let buttonFrame = NSApplication.shared.keyWindow?.contentView?.convert(NSRect(x: 0, y: 0, width: 50, height: 30), to: nil) ?? NSRect(x: 0, y: 0, width: 50, height: 30)
                        withAnimation {
                            clearClipboard(context: context)
                            showToast(message: "Cleared the Clipboard!", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                        }
                    }) {
                        Text("Clear Clipboard")
                            .onAppear {
                                clipboardChangeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
                                    checkClipboard(context: context)
                                }
                            }
                    }
                    .buttonStyle(LinkButtonStyle())
                }
                
                }
            
        }
        .toast(isShowing: $showToast, message: toastMessage, position: toastPosition)
    }
    
    func checkClipboard(context: ModelContext) {
        var newItem: ClipboardItem?
        if clipboardContentType().0 == .text {
            guard let content = NSPasteboard.general.string(forType: .string), !content.isEmpty else { return }
            
            if !content.isEmpty {
                if clipboardItems.firstIndex(where: {
                    if $0.contentType == .text {
                        return $0.content! == content
                    } else {
                        return false
                    }
                }) == nil {
                    newItem = ClipboardItem(content: content, contentType: .text)
                    
                }
            }
        } else {
            guard let imageData = NSPasteboard.general.data(forType: clipboardContentType().1!) else { return }
            
            if !imageData.isEmpty {
                if clipboardItems.firstIndex(where: {
                    if $0.contentType == .image {
                        return $0.imageData! == imageData
                    } else {
                        return false
                    }
                }) == nil {
                    newItem = ClipboardItem(imageData: imageData, contentType: .image)
                }
            }
        }
        if newItem != nil {
            context.insert(newItem!)
        }
    }
    
    func clipboardContentType() -> (ContentType, NSPasteboard.PasteboardType?) {
        let image_types: [NSPasteboard.PasteboardType] = [.png, .tiff]
        let _type = NSPasteboard.general.types?.first
        if image_types.contains(_type!) {
            return (.image, _type!)
        } else {
            return (.text, nil)
        }
    }

    func clearClipboard(context: ModelContext) {
        for item in clipboardItems {
            context.delete(item)
        }
    }

    func removeClipboardItem(context: ModelContext, at index: Int) {
        guard index >= 0, index < clipboardItems.count else { return }
        context.delete(clipboardItems[index])
    }

    func toggleFavourite(context: ModelContext, for item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems[index].isFavourite.toggle()
            try! context.save()
        }
    }
    
    func dataToImage(_ value: Data) -> Image {
        #if canImport(AppKit)
            let image = NSImage(data: value) ?? NSImage()
            return Image(nsImage: image)
        #else
            return Image(systemName: "photo.fill")
        #endif
    }

    func showToast(message: String, position: CGPoint) {
        toastMessage = message
        toastPosition = position
        showToast.toggle()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast.toggle()
        }
    }
}
