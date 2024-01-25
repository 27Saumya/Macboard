import Foundation
import SwiftUI
import AppKit
import SwiftData
import Cocoa


struct ClipboardItemListView: View {
    
    @Environment(\.modelContext) private var context
    
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastPosition: CGPoint = .zero
    
    @Query(sort: [SortDescriptor(\ClipboardItem.isFavourite, order: .reverse), SortDescriptor(\ClipboardItem.createdAt, order: .reverse)]) var clipboardItems: [ClipboardItem]
    
    @State private var clipboardChangeTimer: Timer?

    var body: some View {
        NavigationSplitView {
            List {
                Section {
                    ForEach(clipboardItems) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                if item.contentType == .text {
                                    NavigationLink {
                                        DetailedView(clipboardItem: item)
                                    } label: {
                                        HStack {
                                            if item.content!.isValidURL {
                                                Image(systemName: "link.circle.fill")
                                            } else {
                                                Image(systemName: "doc.text.fill")
                                            }
                                            Text(item.content!)
                                                .lineLimit(1)
                                        }
                                    }
                                } else {
                                    NavigationLink {
                                        DetailedView(clipboardItem: item)
                                    } label: {
                                        HStack{
                                            Image(systemName: "photo.fill")
                                            Text(dataToImage(item.imageData!).1)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        let buttonFrame = NSApplication.shared.keyWindow?.contentView?.convert(NSRect(x: 0, y: 0, width: 50, height: 30), to: nil) ?? NSRect(x: 0, y: 0, width: 50, height: 30)
                                        toggleFavourite(context: context, for: item)
                                        showToast(message: item.isFavourite ? "Added to Favourites" : "Removed from Favourites", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
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
            .frame(minWidth: 300, idealWidth: 350)
            .listStyle(SidebarListStyle())
            .navigationTitle("Clipboard History")
            .toast(isShowing: $showToast, message: toastMessage, position: toastPosition)
        } detail: {
            Text("Select an item to get its detailed view")
                .padding()
                .bold()
        }
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

    func showToast(message: String, position: CGPoint) {
        toastMessage = message
        toastPosition = position
        showToast.toggle()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showToast.toggle()
        }
    }
}
