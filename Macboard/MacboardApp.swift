import SwiftUI
import SwiftData
import Cocoa
import HotKey

@main
struct MacboardApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
