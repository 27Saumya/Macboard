import SwiftUI

@main
struct MacboardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 500, idealWidth: 500, maxWidth: 500, minHeight: 400, idealHeight: 400, maxHeight: 400)
        }
    }
}
