import SwiftUI
import SwiftData

@main
struct MacboardApp: App {
    var body: some Scene {
        WindowGroup {
            ClipboardItemListView()
                .frame(minWidth: 500, idealWidth: 500, maxWidth: 500, minHeight: 400, idealHeight: 400, maxHeight: 400)
        }
        .modelContainer(for: [ClipboardItem.self])
        .windowResizability(.contentSize)
    }
}
