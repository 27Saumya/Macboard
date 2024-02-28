import SwiftUI
import Cocoa
import CoreData
import HotKey
import Settings

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    var popover: NSPopover!
    let openHotKey = HotKey(key: .v, modifiers: [.shift, .command])
    
    let GeneralSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .general,
            title: "General",
            toolbarIcon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General Settings")!
        ) {
            GeneralSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    let StorageSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .storage,
            title: "Storage",
            toolbarIcon: NSImage(systemSymbolName: "externaldrive", accessibilityDescription: "Storage Settings")!
        ) {
            StorageSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    let AboutSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .about,
            title: "About",
            toolbarIcon: NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About Macboard")!
        ) {
            AboutSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        let rootView = ClipboardItemListView(appDelegate: self).environment(\.managedObjectContext, PersistanceController.shared.container.viewContext)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Macboard")
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
    
    @objc func openSettings() {
        SettingsWindowController(
            panes: [
                GeneralSettingsViewController(),
                StorageSettingsViewController(),
                AboutSettingsViewController()
            ],
            style: .toolbarItems,
            animated: true,
            hidesToolbarForSingleItem: true
        ).show()
    }
    
}
