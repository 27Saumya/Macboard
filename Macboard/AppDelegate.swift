import Cocoa
import HotKey
import SwiftUI
import CoreData

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    var popover: NSPopover!
    var preferencesWindow: NSWindow!
    let openHotKey = HotKey(key: .v, modifiers: [.shift, .command])
    
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        let rootView = ClipboardItemListView(appDelegate: self).environment(\.managedObjectContext, PersistanceController.shared.container.viewContext)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: "list.bullet.clipboard.fill", accessibilityDescription: "Macboard")
            statusButton.action = #selector(togglePopover)
        }
        
        openHotKey.keyUpHandler = {
            self.togglePopover()
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
    
    @objc func openPreferencesWindow() {
        if nil == preferencesWindow {
            let preferencesView = SettingsView()
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false)
            preferencesWindow.center()
            preferencesWindow.title = "Preferences"
            preferencesWindow.isReleasedWhenClosed = false
            preferencesWindow.contentView = NSHostingView(rootView: preferencesView)
            preferencesWindow.level = .floating
        }
        preferencesWindow.makeKeyAndOrderFront(nil)
    }
    
}
