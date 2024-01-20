//
//  ContentView.swift
//  Macboard
//
//  Created by Saumya Patel on 20/01/24.
//

// ContentView.swift
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ClipboardManagerViewModel()

    var body: some View {
        VStack {
            Text("Macboard - The Minimalistic Clipboard Manager for MacOS!")
                .font(.largeTitle)
                .padding()

            ClipboardItemListView(viewModel: viewModel)
                .padding()

            // Add more UI components as needed
        }
    }
}

#Preview {
    ContentView()
}
