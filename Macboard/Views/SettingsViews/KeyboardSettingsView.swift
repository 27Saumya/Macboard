import SwiftUI
import Settings
import KeyboardShortcuts

struct KeyboardSettingsView: View {
    
    var body: some View {
        Settings.Container(contentWidth: 350) {
            Settings.Section(title: "") {
                VStack(alignment: .leading) {
                    Form {
                        KeyboardShortcuts.Recorder("Toggle Macboard", name: .toggleMacboard)
                        KeyboardShortcuts.Recorder("Clear Clipboard", name: .clearClipboard)
                    }
                }
            }
        }
    }
}

