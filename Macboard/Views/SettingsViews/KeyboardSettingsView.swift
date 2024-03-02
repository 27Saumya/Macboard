import SwiftUI
import Settings
import KeyboardShortcuts

struct KeyboardSettingsView: View {
    
    var body: some View {
        Settings.Container(contentWidth: 400) {
            Settings.Section(title: "") {
                VStack(alignment: .center) {
                    Form {
                        KeyboardShortcuts.Recorder("Toggle Macboard:", name: .toggleMacboard)
                            .padding(.leading, 70)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    Divider()
                        .padding(.vertical, 4)
                    Form {
                        KeyboardShortcuts.Recorder("Clear Clipboard:", name: .clearClipboard)
                        KeyboardShortcuts.Recorder("Copy & Hide Macboard:", name: .copyAndHide)
                        KeyboardShortcuts.Recorder("Copy & Don't Hide Macboard:", name: .copyItem)
                        KeyboardShortcuts.Recorder("Toggle Pin:", name: .togglePin)
                        KeyboardShortcuts.Recorder("Delete Item:", name: .deleteItem)
                    }
                    Text("Custom keyboard shortcuts require a re-launch to get reflected")
                        .padding(.top, 6)
                        .opacity(0.8)
                        .font(.footnote)
                    Button {
                        relaunch()
                    } label: {
                        Text("Relaunch Now")
                            .font(.footnote)
                    }
                    .padding(.top, 2)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    func relaunch(afterDelay seconds: TimeInterval = 0.5) -> Never {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep \(seconds); open \"\(Bundle.main.bundlePath)\""]
        task.launch()
        
        NSApp.terminate(self)
        exit(0)
    }
}
