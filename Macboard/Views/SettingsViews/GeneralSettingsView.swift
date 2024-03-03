import SwiftUI
import Settings
import LaunchAtLogin
import Defaults

struct GeneralSettingsView: View {
    
    @Default(.autoUpdate) var autoUpdate
    @Default(.showSearchbar) var showSearchbar
    @Default(.showUrlMetadata) var showUrlMetadata
    @Default(.menubarIcon) var menubarIcon
    
    var body: some View {
        Settings.Container(contentWidth: 300) {
            Settings.Section(title: "") {
                VStack(alignment: .leading) {
                    LaunchAtLogin.Toggle()
                    Toggle("Auto-update Macboard", isOn: $autoUpdate)
                    Divider()
                        .padding(.vertical, 8)
                    Toggle("Show search bar", isOn: $showSearchbar)
                    Toggle("Show URL metadata", isOn: $showUrlMetadata)
                    Picker(selection: $menubarIcon, label: Text("Menu bar icon")) {
                        Image(systemName: "doc.on.clipboard")
                            .tag(MenubarIcon.normal)
                        Image(systemName: "doc.on.clipboard.fill")
                            .tag(MenubarIcon.fill)
                        Image(systemName: "paperclip")
                            .tag(MenubarIcon.clip)
                        Image(systemName: "scissors")
                            .tag(MenubarIcon.scissors)
                    }
                    .frame(width: 150)
                    Text("Icon changes require a re-launch to get reflected")
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
                }
            }
        }
    }
}
