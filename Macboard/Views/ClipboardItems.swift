import SwiftUI
import CoreData
import Cocoa
import PopupView
import HotKey

struct ClipboardItemListView: View {
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @StateObject var viewModel = MetadataViewModel()
    
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isShowingConfirmationDialog: Bool = false
    @State private var showPreferences: Bool = false
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
    @State private var clipboardChangeTimer: Timer?
    @State private var hovered: Bool = false
    @State private var hoveredItem: ClipboardItem?
    @State var selectedItem: ClipboardItem?
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.isPinned, order: .reverse), 
                                    SortDescriptor(\.createdAt, order: .reverse)])
    var clipboardItems: FetchedResults<ClipboardItem>
    @FetchRequest(sortDescriptors: [SortDescriptor(\.isPinned, order: .reverse),
                                    SortDescriptor(\.createdAt, order: .reverse)])
    var rawClipboardItems: FetchedResults<ClipboardItem>
    let dataManager = CoreDataManager()
    let pasteKey = HotKey(key: .return, modifiers: [.option])
    let appDelegate: AppDelegate

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(clipboardItems) { item in
                    HStack {
                        if item.contentType == "Text" {
                            NavigationLink {
                                DetailedView(clipboardItem: item, vm: viewModel)
                                    .onAppear {
                                        selectedItem = item
                                        if item.content!.isValidURL {
                                            viewModel.fetchMetadata(item.content!)
                                        }
                                    }
                                    .onChange(of: item) { newItem in
                                        selectedItem = newItem
                                        if newItem.content!.isValidURL {
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
                                    .onAppear {
                                        selectedItem = item
                                        }
                                    .onChange(of: item) { newItem in
                                        selectedItem = newItem
                                    }
                            
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
                                showToast(item.isPinned ? "Pinned" : "Unpinned")
                            }
                        }) {
                            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        }
                        .buttonStyle(LinkButtonStyle())
                        
                        Button(action: {
                            withAnimation {
                                dataManager.deleteItem(item: item)
                                showToast("Removed from Clipboard")
                            }
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(LinkButtonStyle())
                        
                        Button(action: {
                            withAnimation {
                                copyItem(item)
                                showToast("Copied to clipboard")
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
            .popup(isPresented: $showToast) {
                ToastTopFirst(message: toastMessage)
            } customize: {
                $0
                    .type(.toast)
                    .position(.bottom)
                    .animation(.easeInOut)
                    .closeOnTapOutside(true)
                    .autohideIn(1.25)
            }
            .onAppear {
                pasteKey.keyUpHandler = {
                    if appDelegate.popover.isShown {
                        if let selectedItem = selectedItem {
                            copyItem(selectedItem)
                            appDelegate.togglePopover()
                            let vKeyCode: UInt16 = 9
                            let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true)
                            keyDownEvent?.flags = CGEventFlags.maskCommand
                            keyDownEvent?.post(tap: CGEventTapLocation.cgAnnotatedSessionEventTap)
                            
                            let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false)
                            keyUpEvent?.flags = CGEventFlags.maskCommand
                            keyUpEvent?.post(tap: CGEventTapLocation.cgAnnotatedSessionEventTap)
                        }
                    }
                }
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
                        showToast("Cleard the clipboard history")
                    }
                }
                Button("No", role: .destructive) { }
            }
            
            Divider()
            
            Button(action: {
                showPreferences = true
            }) {
                Text("Preferences")
                    .fontWeight(.medium)
                    .padding(.leading, 8)
                Spacer()
                HStack {
                    Image(systemName: "command")
                        .padding(.trailing, -4)
                    Text(",")
                        .fontWeight(.regular)
                }
                .padding(.trailing, 8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, -8)
            .keyboardShortcut(",")
            .sheet(isPresented: $showPreferences) {
                SettingsView()
                    .frame(width: 400, height: 250)
            }
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
    
    func showToast(_ message: String) {
        toastMessage = message
        showToast = true
    }
}
