import AppKit

struct Accessibility {
    private static var alert: NSAlert {
        var settingsName = "System Settings"
        var settingsPane = "Privacy & Security settings"
        if #unavailable(macOS 13.0) {
            settingsName = "System Preferences"
            settingsPane = "Security & Privacy preferences"
        }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "\"Macboard\" would like to automate your keyboard using accessibility features"
        alert.addButton(withTitle: "Deny")
        alert.addButton(withTitle: "Open \(settingsName)")
        alert.icon = NSImage(named: "NSSecurity")
        
        alert.informativeText = "Grant access to this application in \(settingsPane), located in \(settingsName).\n\nClick the \"+\" button, select Macboard and enable access by toggling the button next to it"
        
        return alert
    }
    
    private static var allowed: Bool { AXIsProcessTrustedWithOptions(nil) }
    private static let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )
    
    static func check() {
        guard !allowed else { return }
        DispatchQueue.main.async {
            if alert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn,
               let url = url {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
