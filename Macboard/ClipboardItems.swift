import SwiftUI
import CoreData
import Cocoa

struct ClipboardItemListView: View {
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @StateObject var viewModel = MetadataViewModel()
    
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastPosition: CGPoint = .zero
    @State private var isShowingConfirmationDialog = false
    @State private var searchText = ""
        var query: Binding<String> {
            Binding {
                searchText
            } set: { newValue in
                searchText = newValue
                clipboardItems.nsPredicate = newValue.isEmpty
                               ? nil
                : NSPredicate(format: "content CONTAINS %@", newValue)
            }
        }
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.isPinned, order: .reverse), 
                                    SortDescriptor(\.createdAt, order: .reverse)])
    var clipboardItems: FetchedResults<ClipboardItem>
    @FetchRequest(sortDescriptors: [SortDescriptor(\.isPinned, order: .reverse),
                                    SortDescriptor(\.createdAt, order: .reverse)])
    var rawClipboardItems: FetchedResults<ClipboardItem>
    
    @State private var clipboardChangeTimer: Timer?
    
    let buttonFrame = NSApplication.shared.keyWindow?.contentView?.convert(NSRect(x: 0, y: 0, width: 50, height: 30), to: nil) ?? NSRect(x: 0, y: 0, width: 50, height: 30)
    let dataManager = CoreDataManager()

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(clipboardItems) { item in
                    HStack {
                        if item.contentType == "Text" {
                            NavigationLink {
                                DetailedView(clipboardItem: item, vm: viewModel)
                                    .onAppear {
                                        if item.content!.isValidURL {
                                            viewModel.fetchMetadata(item.content!)
                                        }
                                    }
                                    .onChange(of: item) { [item] newItem in
                                        if item.content!.isValidURL {
                                            viewModel.fetchMetadata(newItem.content!)
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
                                dataManager.togglePin(for: item)
                                showToast(message: item.isPinned ? "Pinned" : "Unpinned", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                            }
                        }) {
                            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        }
                        .buttonStyle(LinkButtonStyle())
                        
                        Button(action: {
                            withAnimation {
                                dataManager.deleteItem(item: item)
                                showToast(message: "Removed from Clipboard", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                            }
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(LinkButtonStyle())
                        
                        Button(action: {
                            withAnimation {
                                NSPasteboard.general.clearContents()
                                if item.contentType == "Image" {
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
                        .validKeyboardShortcut(number: clipboardItems.firstIndex(of: item)!, modifiers: [.command])
                    }
                }
                
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Clipboard History")
            .searchable(text: query, placement: .sidebar, prompt: "type to search...")
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
                    isShowingConfirmationDialog = true
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
            .confirmationDialog("Are you sure you want to clear your clipboard history?", 
                                isPresented: $isShowingConfirmationDialog) {
                Button("Yes") {
                    withAnimation {
                        dataManager.clearClipboard()
                        showToast(message: "Cleard the clipboard history", position: CGPoint(x: buttonFrame.midX, y: buttonFrame.minY))
                    }
                }
                Button("No", role: .destructive) { }
            }
            
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
    
    func checkClipboard(context: NSManagedObjectContext) {
        if clipboardContentType().0 == "Text" {
            guard let content = NSPasteboard.general.string(forType: .string), !content.isEmpty else { return }
            
            if !content.isEmpty {
                if rawClipboardItems.firstIndex(where: {
                    if $0.contentType == "Text" {
                        return $0.content! == content
                    } else {
                        return false
                    }
                }) == nil {
                    let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
                    dataManager.addToClipboard(content: content, contentType: "Text", sourceApp: sourceApp, context: context)
                } else {
                    let existingItem = rawClipboardItems.first(where: {
                        if $0.contentType == "Text" {
                            return $0.content! == content
                        } else {
                            return false
                        }
                    })
                    dataManager.isReCopied(item: existingItem!)
                }
            }
        } else {
            let contentType = clipboardContentType().1
            if contentType != nil {
                guard let imageData = NSPasteboard.general.data(forType: contentType!) else { return }
                
                if !imageData.isEmpty {
                    if rawClipboardItems.firstIndex(where: {
                        if $0.contentType == "Image" {
                            return $0.imageData! == imageData
                        } else {
                            return false
                        }
                    }) == nil {
                        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
                        dataManager.addToClipboard(imageData: imageData, contentType: "Image", sourceApp: sourceApp, context: context)
                    } else {
                        let existingItem = rawClipboardItems.first(where: {
                            if $0.contentType == "Image" {
                                return $0.imageData! == imageData
                            } else {
                                return false
                            }
                        })
                        dataManager.isReCopied(item: existingItem!)
                    }
                }
            }
        }
    }
    
    func clipboardContentType() -> (String?, NSPasteboard.PasteboardType?) {
        let image_types: [NSPasteboard.PasteboardType] = [.png, .tiff]
        let _type = NSPasteboard.general.types?.first
        if _type != nil {
            if image_types.contains(_type!) {
                return ("Image", _type!)
            } else {
                return ("Text", nil)
            }
        } else {
            return (nil, nil)
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
