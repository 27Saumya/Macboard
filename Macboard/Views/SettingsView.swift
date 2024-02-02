import SwiftUI
import Cocoa

struct SettingsView: View {
    @AppStorage("launchOnStartup") private var launchOnStartup = false
    
    var body: some View {
        Form {
            Toggle("Launch on startup", isOn: $launchOnStartup)
        }
        .padding(20)
        .frame(width: 350, height: 100)
    }
}
