import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ClipboardManagerViewModel()

    var body: some View {
        ClipboardItemListView(viewModel: viewModel)
            .padding()
    }
}
