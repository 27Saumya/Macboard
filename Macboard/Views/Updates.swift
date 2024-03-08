import SwiftUI
import Sparkle
import Defaults


final class UpdaterViewController: ObservableObject {
    let updaterController: SPUStandardUpdaterController
    
    @Published var canCheckForUpdates = false
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
    
    func toggleAutoUpdates(_ value: Bool) {
        updaterController.updater.automaticallyChecksForUpdates = value
    }
    
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

struct CheckForUpdatesView: View {
    
    @ObservedObject var updaterViewController: UpdaterViewController
    
    @Default(.autoUpdate) var autoUpdate
    
    var body: some View {
        Toggle("Automatically check for updates", isOn: $autoUpdate)
            .onChange(of: autoUpdate) { newValue in
                updaterViewController.toggleAutoUpdates(newValue)
            }
        Button {
            updaterViewController.checkForUpdates()
        } label: {
            Text("Check Now")
                .font(.footnote)
        }
        .disabled(!updaterViewController.canCheckForUpdates)
        .padding(.top, 1)
    }
}
