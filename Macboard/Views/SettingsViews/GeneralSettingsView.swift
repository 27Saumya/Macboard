import SwiftUI
import Settings
import LaunchAtLogin
import Defaults

struct GeneralSettingsView: View {
    
    @Default(.autoUpdate) var autoUpdate
    @Default(.showSearchbar) var showSearchbar
    @Default(.showUrlMetadata) var showUrlMetadata
    
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
                }
            }
        }
    }
}
