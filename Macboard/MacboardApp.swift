import SwiftUI
import SwiftData

@main
struct MacboardApp: App {
    var body: some Scene {
        WindowGroup {
            ClipboardItemListView()
                .frame(minWidth: 700, idealWidth: 700, maxWidth: 700, minHeight: 500, idealHeight: 500, maxHeight: 500)
        }
        .modelContainer(for: [ClipboardItem.self])
        .windowResizability(.contentSize)
    }
}
