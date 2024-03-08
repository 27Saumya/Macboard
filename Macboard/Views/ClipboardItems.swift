import SwiftUI
import Cocoa
import PopupView
import Defaults
import KeyboardShortcuts
import Sauce

struct ClipboardItemListView: View {
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @Default(.showSearchbar) var showSearchbar
    @Default(.allowedTypes) var allowedTypes
    @Default(.maxItems) var maxItems
    @Default(.searchType) var searchType
    
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
            : NSPredicate(format: "content CONTAINS\(searchType == .insensitive ? "[cd]" : "") %@", newValue)
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
    
    let clearClipboardShortcut = KeyboardShortcuts.Name("clearClipboard").shortcut ?? KeyboardShortcuts.Shortcut(.delete, modifiers: [.command])
    let pasteShortcut = KeyboardShortcuts.Name("paste").shortcut ?? KeyboardShortcuts.Shortcut(.return, modifiers: [])
    let copyItemShortcut = KeyboardShortcuts.Name("copyItem").shortcut ?? KeyboardShortcuts.Shortcut(.return, modifiers: [.command])
    let togglePinShortcut = KeyboardShortcuts.Name("togglePin").shortcut ?? KeyboardShortcuts.Shortcut(.p, modifiers: [.command])
    let deleteItemShortcut = KeyboardShortcuts.Name("deleteItem").shortcut ?? KeyboardShortcuts.Shortcut(.delete, modifiers: [])
    
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
                                            Image(systemName: "doc.plaintext.fill")
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
                                        if item.contentType == "Image" {
                                            Image(systemName: "photo.fill")
                                            Text(dataToImage(item.imageData!).1)
                                                .lineLimit(1)
                                            dataToImage(item.imageData!).0
                                                .resizable()
                                                .frame(width: 14, height: 14)
                                        } else {
                                            Image(systemName: "doc.fill")
                                            Text(item.content!)
                                                .lineLimit(1)
                                        }
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
                                    if selectedItem != nil {
                                        if item == selectedItem! {
                                            selectedItem = nil
                                        }
                                    }
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
                    }
                    
                }
                .listStyle(SidebarListStyle())
                .navigationTitle("Clipboard History")
                .searchable(text: query, placement: showSearchbar ? .sidebar : .toolbar, prompt: "type to search...")
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
                        if keyboardShortcutsHandler13(event) {
                            return nil
                        }
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
                        if let shortcut = KeyboardShortcuts.Name("clearClipboard").shortcut {
                            Text(shortcutToText(shortcut))
                                .opacity(0.8)
                                .padding(.trailing, 4)
                        } else {
                            Text("⌘ ⌫")
                                .opacity(0.8)
                                .padding(.trailing, 4)
                        }
                    }
                }
                .buttonStyle(ItemButtonStyle())
                .frame(maxWidth: .infinity, minHeight: 15, idealHeight: 15, maxHeight: 15)
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
                    appDelegate.openSettings()
                } label: {
                    HStack {
                        Text("Settings...")
                            .padding(.leading, 8)
                        Spacer()
                        Text("⌘ ,")
                            .opacity(0.8)
                            .padding(.trailing, 4)
                    }
                }
                .buttonStyle(ItemButtonStyle())
                .background(.clear)
                .padding(.top, -8)
                .frame(maxWidth: .infinity, minHeight: 18, idealHeight: 18, maxHeight: 18)
                .keyboardShortcut(",")
                
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
                                            Image(systemName: "doc.plaintext.fill")
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
                                        if item.contentType == "Image" {
                                            Image(systemName: "photo.fill")
                                            Text(dataToImage(item.imageData!).1)
                                                .lineLimit(1)
                                            dataToImage(item.imageData!).0
                                                .resizable()
                                                .frame(width: 14, height: 14)
                                        } else {
                                            Image(systemName: "doc.fill")
                                            Text(item.content!)
                                                .lineLimit(1)
                                        }
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
                                    if selectedItem != nil {
                                        if item == selectedItem! {
                                            selectedItem = nil
                                        }
                                    }
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
                    }
                    
                }
                .listStyle(SidebarListStyle())
                .navigationTitle("Clipboard History")
                .searchable(text: query, placement: showSearchbar ? .sidebar : .toolbar, prompt: "type to search...")
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
                        if keyboardShortcutsHandler12(event) {
                            return nil
                        }
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
                        if let shortcut = KeyboardShortcuts.Name("clearClipboard").shortcut {
                            Text(shortcutToText(shortcut))
                                .opacity(0.8)
                                .padding(.trailing, 4)
                        } else {
                            Text("⌘ ⌫")
                                .opacity(0.8)
                                .padding(.trailing, 4)
                        }
                    }
                }
                .buttonStyle(ItemButtonStyle())
                .frame(maxWidth: .infinity, minHeight: 15, idealHeight: 15, maxHeight: 15)
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
                    appDelegate.openSettings()
                } label: {
                    HStack {
                        Text("Settings...")
                            .padding(.leading, 8)
                        Spacer()
                        Text("⌘ ,")
                            .opacity(0.8)
                            .padding(.trailing, 4)
                    }
                }
                .buttonStyle(ItemButtonStyle())
                .background(.clear)
                .padding(.top, -8)
                .frame(maxWidth: .infinity, minHeight: 18, idealHeight: 18, maxHeight: 18)
                .keyboardShortcut(",")
                
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
        let contentType = clipboardContentType().0
        if contentType == nil {
            return
        }
        if clipboardItems.count > maxItems && maxItems != 0 {
            let itemsToRemoveCount = clipboardItems.count - maxItems
            for _ in 0..<itemsToRemoveCount {
                dataManager.deleteItem(item: clipboardItems.last!)
            }
        }
        if contentType == "Text" && allowedTypes.contains("Text") {
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
        } else if contentType == "Image" && allowedTypes.contains("Image") {
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
                        dataManager.addToClipboard(content: "Image", imageData: imageData, contentType: "Image", sourceApp: sourceApp, context: context)
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
        } else if contentType == "File" && allowedTypes.contains("File") {
            guard let fileData = NSPasteboard.general.data(forType: .fileURL),
                  let fileURL = URL(dataRepresentation: fileData, relativeTo: nil) else { return }
            
            if rawClipboardItems.firstIndex(where: {
                if $0.contentType == "File" {
                    return $0.content! == fileURL.absoluteString
                } else {
                    return false
                }
            }) == nil {
                let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
                dataManager.addToClipboard(content: fileURL.absoluteString, fileURL: fileURL, contentType: "File", sourceApp: sourceApp, context: context)
            } else {
                let existingItem = rawClipboardItems.first(where: {
                    if $0.contentType == "File" {
                        return $0.content! == fileURL.absoluteString
                    } else {
                        return false
                    }
                })
                dataManager.isReCopied(item: existingItem!)
            }
        }
    }
    
    func clipboardContentType() -> (String?, NSPasteboard.PasteboardType?) {
        let image_types: [NSPasteboard.PasteboardType] = [.png, .tiff]
        let _type = NSPasteboard.general.types?.first
        if _type != nil {
            if image_types.contains(_type!) {
                return ("Image", _type!)
            } else if _type == .fileURL {
                return ("File", nil)
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
    
    func keyboardShortcutsHandler13(_ event: NSEvent) -> Bool {
        if !appDelegate.popoverFocused {
            return false
        }
        
        if isShowingConfirmationDialog {
            return false
        }
        
        if let responder = NSApplication.shared.keyWindow?.firstResponder {
            if responder.className.contains("SearchTextView") {
                return false
            }
        }
        
        guard let shortcut = KeyboardShortcuts.Shortcut(event: event) else { return false }
        
        switch shortcut {
            
        case clearClipboardShortcut:
            withAnimation {
                isShowingConfirmationDialog = true
            }
            return true
            
        case pasteShortcut:
            if selectedItem != nil {
                withAnimation {
                    copyToClipboard(selectedItem!)
                    appDelegate.togglePopover()
                    Accessibility.check()
                    
                    DispatchQueue.main.async {
                        let vCode = Sauce.shared.keyCode(for: .v)
                        let source = CGEventSource(stateID: .combinedSessionState)
                        source?.setLocalEventsFilterDuringSuppressionState([.permitLocalMouseEvents, .permitSystemDefinedEvents],
                                                                           state: .eventSuppressionStateSuppressionInterval)
                        let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: true)
                        let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: false)
                        keyVDown?.flags = .maskCommand
                        keyVUp?.flags = .maskCommand
                        keyVDown?.post(tap: .cgAnnotatedSessionEventTap)
                        keyVUp?.post(tap: .cgAnnotatedSessionEventTap)
                    }
                }
                return true
            } else {
                return false
            }
            
        case copyItemShortcut:
            if selectedItem != nil {
                withAnimation {
                    copyToClipboard(selectedItem!)
                    showToast("Copied to Clipboard")
                }
                return true
            } else {
                return false
            }
            
        case togglePinShortcut:
            if selectedItem != nil {
                withAnimation {
                    dataManager.togglePin(for: selectedItem!)
                    showToast(selectedItem!.isPinned ? "Pinned" : "Unpinned")
                }
                return true
            } else {
                return false
            }
            
        case deleteItemShortcut:
            if selectedItem != nil {
                withAnimation {
                    dataManager.deleteItem(item: selectedItem!)
                    showToast("Removed from clipboard")
                    selectedItem = nil
                }
                return true
            } else {
                return false
            }
            
        default:
            return false
        }
    }
    
    
    func keyboardShortcutsHandler12(_ event: NSEvent) -> Bool {
        if !appDelegate.popoverFocused {
            return false
        }
        
        if let responder = NSApplication.shared.keyWindow?.firstResponder {
            if responder.className.contains("SearchTextView") {
                return false
            }
        }
        
        let upArrowKey = KeyboardShortcuts.Shortcut(.upArrow, modifiers: [])
        let downArrowKey = KeyboardShortcuts.Shortcut(.downArrow, modifiers: [])
        
        guard let shortcut = KeyboardShortcuts.Shortcut(event: event) else { return false }
        
        switch shortcut {
            
        case clearClipboardShortcut:
            withAnimation {
                isShowingConfirmationDialog = true
            }
            return true
            
        case pasteShortcut:
            if selectedItem != nil {
                withAnimation {
                    copyToClipboard(selectedItem!)
                    appDelegate.togglePopover()
                }
                return true
            } else {
                return false
            }
            
        case copyItemShortcut:
            if selectedItem != nil {
                withAnimation {
                    copyToClipboard(selectedItem!)
                    showToast("Copied to Clipboard")
                }
                return true
            } else {
                return false
            }
            
        case togglePinShortcut:
            if selectedItem != nil {
                withAnimation {
                    dataManager.togglePin(for: selectedItem!)
                    showToast(selectedItem!.isPinned ? "Pinned" : "Unpinned")
                }
                return true
            } else {
                return false
            }
            
        case deleteItemShortcut:
            if selectedItem != nil {
                withAnimation {
                    dataManager.deleteItem(item: selectedItem!)
                    showToast("Removed from clipboard")
                    selectedItem = nil
                }
                return true
            } else {
                return false
            }
            
        case upArrowKey:
            if selectedItem != nil {
                let selectedItemIndex = clipboardItems.firstIndex(of: selectedItem!)!
                if selectedItemIndex-1 != -1 {
                    let nextItem = clipboardItems[selectedItemIndex-1]
                    selectedItem = nextItem
                }
            } else {
                selectedItem = clipboardItems.first!
            }
            return true
            
        case downArrowKey:
            if selectedItem != nil {
                let selectedItemIndex = clipboardItems.firstIndex(of: selectedItem!)!
                if selectedItemIndex+1 != clipboardItems.count {
                    let nextItem = clipboardItems[selectedItemIndex+1]
                    selectedItem = nextItem
                }
            } else {
                selectedItem = clipboardItems.first!
            }
            return true
            
        default:
            return false
        }
    }
}
