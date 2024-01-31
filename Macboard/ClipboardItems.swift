import Foundation
import SwiftUI
import AppKit
import SwiftData
import Cocoa

struct ClipboardItemListView: View {
    
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @StateObject var viewModel = MetadataViewModel()
    
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastPosition: CGPoint = .zero
    
    @Query(sort: [SortDescriptor(\ClipboardItem.isFavourite, order: .reverse), SortDescriptor(\ClipboardItem.createdAt, order: .reverse)]) var clipboardItems: [ClipboardItem]
    
    @State private var clipboardChangeTimer: Timer?
    
    let buttonFrame = NSApplication.shared.keyWindow?.contentView?.convert(NSRect(x: 0, y: 0, width: 50, height: 30), to: nil) ?? NSRect(x: 0, y: 0, width: 50, height: 30)

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(clipboardItems) { item in
                    HStack {
                        if item.contentType == .text {
                            NavigationLink {
                                DetailedView(clipboardItem: item, vm: viewModel)
                                    .onAppear {
                                        if item.content!.isValidURL {
                                            viewModel.fetchMetadata(item.content!)
                                        }
                                    }
                                    .onChange(of: item) {
                                        if item.content!.isValidURL {
                                            viewModel.fetchMetadata(item.content!)
                                        }
                                    }
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
                                DetailedView(clipboardItem: item, vm: viewModel)
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
                                toggleFavourite(context: context, for: item)
                                showToast(message: item.isFavourite ? "Pinned" : "Unpinned", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                            }
                        }) {
                            Image(systemName: item.isFavourite ? "pin.fill" : "pin")
                        }
                        .buttonStyle(LinkButtonStyle())
                        
                        Button(action: {
                            withAnimation {
                                removeClipboardItem(context: context, at: clipboardItems.firstIndex(where: { $0.id == item.id })!)
                                showToast(message: "Removed from Clipboard", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                            }
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(LinkButtonStyle())
                        
                        Button(action: {
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
            .listStyle(SidebarListStyle())
            .navigationTitle("Clipboard History")
            .toast(isShowing: $showToast, message: toastMessage, position: toastPosition)
            .onAppear {
                clipboardChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] _ in
                    checkClipboard(context: context)
                }
            }
            
            Divider()
                .background(colorScheme == .light ? .black : .white)
                .opacity(0.5)
            
            Button(action: {
                withAnimation {
                    clearClipboard(context: context)
                    showToast(message: "Copied to Clipboard", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                }
            }) {
                HStack {
                    Text("Clear Clipboard")
                        .fontWeight(.medium)
                        .padding(.leading, 8)
                    Spacer()
                    HStack {
                        Image(systemName: "command")
                        Text("/")
                    }
                    .padding(.trailing, 8)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(minWidth: 300, idealWidth: 350, minHeight: 15, idealHeight: 15, maxHeight: 15)
            .keyboardShortcut("/")
            
            Divider()
            
            Button(action: {
                
            }) {
                Text("Keyboard Shortcuts")
                    .fontWeight(.medium)
                    .padding(.leading, 8)
                Spacer()
                HStack {
                    Image(systemName: "command")
                        .padding(.trailing, -4)
                    Text("K")
                        .fontWeight(.regular)
                }
                .padding(.trailing, 8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, -8)
            .frame(minWidth: 300, idealWidth: 350, minHeight: 18, idealHeight: 18, maxHeight: 18)
            
        .frame(minWidth: 300, idealWidth: 350)
            
        } detail: {
            Text("Select an item to get its detailed view")
                .bold()
                .padding()
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
                } else {
                    let existingItem = clipboardItems.first(where: {
                        if $0.contentType == .text {
                            return $0.content! == content
                        } else {
                            return false
                        }
                    })
                    existingItem?.createdAt = Date.now
                    try! context.save()
                }
            }
        } else {
            let contentType = clipboardContentType().1
            if contentType != nil {
                guard let imageData = NSPasteboard.general.data(forType: contentType!) else { return }
                
                if !imageData.isEmpty {
                    if clipboardItems.firstIndex(where: {
                        if $0.contentType == .image {
                            return $0.imageData! == imageData
                        } else {
                            return false
                        }
                    }) == nil {
                        newItem = ClipboardItem(imageData: imageData, contentType: .image)
                    } else {
                        let existingItem = clipboardItems.first(where: {
                            if $0.contentType == .image {
                                return $0.imageData! == imageData
                            } else {
                                return false
                            }
                        })
                        existingItem?.createdAt = Date.now
                        try! context.save()
                    }
                }
            }
        }
        if newItem != nil {
            context.insert(newItem!)
        }
    }
    
    func clipboardContentType() -> (ContentType?, NSPasteboard.PasteboardType?) {
        let image_types: [NSPasteboard.PasteboardType] = [.png, .tiff]
        let _type = NSPasteboard.general.types?.first
        if _type != nil {
            if image_types.contains(_type!) {
                return (.image, _type!)
            } else {
                return (.text, nil)
            }
        } else {
            return (nil, nil)
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
        try! context.save()
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


