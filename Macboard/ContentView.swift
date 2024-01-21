import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ClipboardManagerViewModel()

    var body: some View {
        VStack {
            Text("Macboard - A Minimalistic Clipboard Manager for MacOS!")
                .font(.largeTitle)
                .padding()

            ClipboardItemListView(viewModel: viewModel)
                .padding()
        }
    }
}

#Preview {
    ContentView()
}
