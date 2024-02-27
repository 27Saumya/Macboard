import SwiftUI
import CoreData
import Cocoa
import PopupView

struct ClipboardItemListView: View {
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @StateObject var viewModel = MetadataViewModel()
    
    @State private var clipboardChangeTimer: Timer?
    @State private var selectedItem: ClipboardItem?
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
            : NSPredicate(format: "content CONTAINS[cd] %@", newValue)
        }
    }
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.isPinned, order: .reverse),
                                    SortDescriptor(\.createdAt, order: .reverse)])
    var clipboardItems: FetchedResults<ClipboardItem>
    @FetchRequest(sortDescriptors: [SortDescriptor(\.isPinned, order: .reverse),
                                    SortDescriptor(\.createdAt, order: .reverse)])
    var rawClipboardItems: FetchedResults<ClipboardItem>
    
    let dataManager = CoreDataManager()
    let appDelegate: AppDelegate
    
    var body: some View {
        if #available(macOS 13.0, *) {
            NavigationSplitView {
                List {
                    ForEach(clipboardItems) { item in
                        HStack {
                            if item.contentType == "Text" {
                                NavigationLink {
                                    DetailedView(clipboardItem: item, vm: viewModel, selectedItem: $selectedItem)
                                        .onAppear {
                                            selectedItem = item
                                            if item.content!.isValidURL {
                                                viewModel.fetchMetadata(item.content!)
                                            }
                                        }
                                        .onChange(of: item) { newItem in
                                            selectedItem = newItem
                                            if newItem.contentType == "Text" {
                                                if newItem.content!.isValidURL {
                                                    viewModel.fetchMetadata(newItem.content!)
                                                }
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
                                    DetailedView(clipboardItem: item, vm: viewModel, selectedItem: $selectedItem)
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
                                    copyToClipboard(item)
                                    showToast("Copied to Clipboard")
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(LinkButtonStyle())
                        }
                        .onKeyboardShortcut(key: .return, modifiers: []) {
                            if selectedItem != nil {
                                withAnimation {
                                    copyToClipboard(selectedItem!)
                                    appDelegate.togglePopover()
                                }
                            }
                        }
                        .onKeyboardShortcut(key: "c", modifiers: [.command]) {
                            if selectedItem != nil {
                                withAnimation {
                                    copyToClipboard(selectedItem!)
                                    showToast("Copied to Clipboard")
                                }
                            }
                        }
                        .onKeyboardShortcut(key: "d", modifiers: [.command]) {
                            if selectedItem != nil {
                                withAnimation {
                                    dataManager.deleteItem(item: selectedItem!)
                                    selectedItem = nil
                                    showToast("Removed from clipboard")
                                }
                            }
                        }
                    }
                    
                }
                .listStyle(SidebarListStyle())
                .navigationTitle("Clipboard History")
                .searchable(text: query, placement: .sidebar, prompt: "type to search...")
                .popup(isPresented: $showToast) {
                    ToastView(message: toastMessage)
                } customize: {
                    $0
                        .type(.toast)
                        .position(.bottom)
                        .animation(.easeInOut)
                        .closeOnTapOutside(true)
                        .autohideIn(1.25)
                }
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
                                .opacity(0.7)
                            Text("/")
                                .opacity(0.7)
                        }
                        .padding(.trailing, 8)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity, minHeight: 15, idealHeight: 15, maxHeight: 15)
                .keyboardShortcut("/")
                .confirmationDialog("Are you sure you want to clear your clipboard history?",
                                    isPresented: $isShowingConfirmationDialog) {
                    Button("Yes") {
                        withAnimation {
                            dataManager.clearClipboard()
                            selectedItem = nil
                            showToast("Cleard the clipboard history")
                        }
                    }
                    Button("No", role: .destructive) { }
                }
                
                Divider()
                
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .fontWeight(.medium)
                        .padding(.leading, 8)
                    Spacer()
                    HStack {
                        Image(systemName: "command")
                            .opacity(0.7)
                            .padding(.trailing, -4)
                        Text("Q")
                        
                            .opacity(0.7)
                    }
                    .padding(.trailing, 6)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, -8)
                .frame(maxWidth: .infinity, minHeight: 18, idealHeight: 18, maxHeight: 18)
                .keyboardShortcut("q")
                
                .frame(minWidth: 300, idealWidth: 350)
                
            } detail: {
                Text("Select an item to get its detailed view")
                    .bold()
                    .padding()
            }
        } else {
            CustomSplitView {
                List {
                    ForEach(clipboardItems) { item in
                        HStack {
                            if item.contentType == "Text" {
                                Button {
                                    selectedItem = item
                                } label: {
                                    HStack {
                                        if item.content!.isValidURL {
                                            Image(systemName: "link.circle.fill")
                                        } else {
                                            Image(systemName: "doc.text.fill")
                                        }
                                        Text(item.content!)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(ItemButtonStyle())
                                
                            } else {
                                Button {
                                    selectedItem = item
                                } label: {
                                    HStack{
                                        Image(systemName: "photo.fill")
                                        Text(dataToImage(item.imageData!).1)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(ItemButtonStyle())
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
                                    copyToClipboard(item)
                                    showToast("Copied to Clipboard")
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(LinkButtonStyle())
                        }
                        .background(selectedItem != nil && selectedItem == item ? Color.accentColor : Color.clear)
                        .onKeyboardShortcut(key: .return, modifiers: []) {
                            if selectedItem != nil {
                                withAnimation {
                                    copyToClipboard(selectedItem!)
                                    appDelegate.togglePopover()
                                }
                            }
                        }
                        .onKeyboardShortcut(key: "c", modifiers: [.command]) {
                            if selectedItem != nil {
                                withAnimation {
                                    copyToClipboard(selectedItem!)
                                    showToast("Copied to Clipboard")
                                }
                            }
                        }
                        .onKeyboardShortcut(key: "d", modifiers: [.command]) {
                            if selectedItem != nil {
                                withAnimation {
                                    dataManager.deleteItem(item: selectedItem!)
                                    selectedItem = nil
                                    showToast("Removed from clipboard")
                                }
                            }
                        }
                    }
                    
                }
                .listStyle(SidebarListStyle())
                .navigationTitle("Clipboard History")
                .searchable(text: query, placement: .sidebar, prompt: "type to search...")
                .popup(isPresented: $showToast) {
                    ToastView(message: toastMessage)
                } customize: {
                    $0
                        .type(.toast)
                        .position(.bottom)
                        .animation(.easeInOut)
                        .closeOnTapOutside(true)
                        .autohideIn(1.25)
                }
                .onAppear {
                    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                        handleNavigation(event)
                        return event
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
                            .padding(.leading, 8)
                        Spacer()
                        HStack {
                            Image(systemName: "command")
                                .opacity(0.7)
                            Text("/")
                                .opacity(0.7)
                        }
                        .padding(.trailing, 8)
                    }
                }
                .buttonStyle(ItemButtonStyle())
                .frame(maxWidth: .infinity, minHeight: 15, idealHeight: 15, maxHeight: 15)
                .keyboardShortcut("/")
                .confirmationDialog("Are you sure you want to clear your clipboard history?",
                                    isPresented: $isShowingConfirmationDialog) {
                    Button("Yes") {
                        withAnimation {
                            dataManager.clearClipboard()
                            selectedItem = nil
                            showToast("Cleard the clipboard history")
                        }
                    }
                    Button("No", role: .destructive) { }
                }
                
                Divider()
                
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .padding(.leading, 8)
                    Spacer()
                    HStack {
                        Image(systemName: "command")
                            .opacity(0.7)
                            .padding(.trailing, -4)
                        Text("Q")
                            .opacity(0.7)
                            .padding(.top, -1)
                    }
                    .padding(.trailing, 6)
                }
                .buttonStyle(.plain)
                .padding(.top, -8)
                .frame(maxWidth: .infinity, minHeight: 18, idealHeight: 18, maxHeight: 18)
                .keyboardShortcut("q")
                
            } detail: {
                if let selectedItem = selectedItem {
                    DetailedView(clipboardItem: selectedItem, vm: viewModel, selectedItem: $selectedItem)
                        .onAppear {
                            if selectedItem.contentType == "Text" {
                                if selectedItem.content!.isValidURL {
                                    viewModel.fetchMetadata(selectedItem.content!)
                                }
                            }
                        }
                        .onChange(of: selectedItem) { newItem in
                            if newItem.contentType == "Text" {
                                if newItem.content!.isValidURL {
                                    viewModel.fetchMetadata(newItem.content!)
                                }
                            }
                        }
                } else {
                    Text("Select an item to get its detailed view")
                        .bold()
                        .padding()
                }
            }
        }
    }
    
    func checkClipboard(context: NSManagedObjectContext) {
        if clipboardContentType().0 == nil {
            return
        }
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
    
    func handleNavigation(_ event: NSEvent) {
        guard let characters = event.charactersIgnoringModifiers else { return }
        switch characters {
        case String(Character(UnicodeScalar(NSUpArrowFunctionKey)!)):
            if selectedItem != nil {
                let selectedItemIndex = clipboardItems.firstIndex(of: selectedItem!)!
                if selectedItemIndex-1 != -1 {
                    let nextItem = clipboardItems[selectedItemIndex-1]
                    selectedItem = nextItem
                }
            } else {
                selectedItem = clipboardItems.first!
            }
        case String(Character(UnicodeScalar(NSDownArrowFunctionKey)!)):
            if selectedItem != nil {
                let selectedItemIndex = clipboardItems.firstIndex(of: selectedItem!)!
                if selectedItemIndex+1 != clipboardItems.count {
                    let nextItem = clipboardItems[selectedItemIndex+1]
                    selectedItem = nextItem
                }
            } else {
                selectedItem = clipboardItems.first!
            }
        default:
            break
        }
    }
}
