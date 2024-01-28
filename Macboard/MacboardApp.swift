import SwiftUI
import SwiftData
import Cocoa

@main
struct MacboardApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        let rootView = ClipboardItemListView().modelContainer(for: [ClipboardItem.self])
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: "list.bullet.clipboard", accessibilityDescription: "Macboard")
            statusButton.action = #selector(togglePopover)
        }
        
        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: 700, height: 500)
        self.popover.behavior = .transient
        self.popover.contentViewController = NSHostingController(rootView: rootView)
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                self.popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
        
    }
    
}
