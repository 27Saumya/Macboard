import SwiftUI
import Settings
import LaunchAtLogin
import Defaults

struct GeneralSettingsView: View {
    
    @Default(.showSearchbar) var showSearchbar
    @Default(.showUrlMetadata) var showUrlMetadata
    @Default(.searchType) var searchType
    @Default(.menubarIcon) var menubarIcon
    
    var body: some View {
        Settings.Container(contentWidth: 300) {
            Settings.Section(title: "") {
                VStack(alignment: .leading) {
                    LaunchAtLogin.Toggle()
                    CheckForUpdatesView(updaterViewController: UpdaterViewController())
                    Divider()
                        .padding(.vertical, 2)
                    Toggle("Show search bar", isOn: $showSearchbar)
                    Toggle("Show URL metadata", isOn: $showUrlMetadata)
                    Picker(selection: $searchType, label: Text("Search")) {
                        Text("Case Sensitive")
                            .tag(SearchType.sensitive)
                        Text("Case Insensitive")
                            .tag(SearchType.insensitive)
                    }
                    .frame(width: 180)
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
                        .padding(.top, 4)
                        .opacity(0.8)
                        .font(.footnote)
                    Button {
                        relaunch()
                    } label: {
                        Text("Relaunch Now")
                            .font(.footnote)
                    }
                    .padding(.top, 1)
                }
            }
        }
    }
}
