import SwiftUI
import Settings

struct AboutSettingsView: View {
    var body: some View {
        Settings.Container(contentWidth: 300) {
            Settings.Section(title: "", verticalAlignment: .center) {
                VStack(alignment: .center) {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    VStack(alignment: .leading) {
                        Text("Macboard")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("- a minimalistic clipboard manager for macOS")
                            .padding(.top, 4)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    Divider()
                    HStack {
                        Button {
                            if let url = URL(string: "https://twitter.com/saums27") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Text("Developer")
                        }
                        Button {
                            if let url = URL(string: "https://saumya.lol/macboard") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Text("Website")
                        }
                        Button {
                            if let url = URL(string: "https://github.com/27Saumya") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Text("Github")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
