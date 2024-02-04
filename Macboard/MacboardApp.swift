import SwiftUI
import Cocoa

@main
struct MacboardApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        Settings { }
    }
}
