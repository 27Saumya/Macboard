import SwiftUI
import Cocoa

struct GeneralSettingsView: View {
    @AppStorage("launchOnStartup") private var launchOnStartup = false
    
    var body: some View {
        Form {
            Toggle("Launch on startup", isOn: $launchOnStartup)
        }
    }
}

struct KeyboardView: View {
    var body: some View {
        Text("generic")
    }
}

struct SettingsView: View {
    @State private var selectedTabIndex = 0
    
    var body: some View {
        VStack {
            Picker(selection: $selectedTabIndex, label: Text("")) {
                Label("General", systemImage: "gear")
                    .tag(0)
                
                Label("Keyboard", systemImage: "keyboard.fill")
                    .tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Spacer()
            
            if selectedTabIndex == 0 {
                GeneralSettingsView()
            } else if selectedTabIndex == 1 {
                KeyboardView()
            }
            
            Spacer()
        }
    }
}

