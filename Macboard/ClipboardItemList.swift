import Foundation
import SwiftUI

struct ClipboardItemListView: View {
    @ObservedObject var viewModel: ClipboardManagerViewModel

    var body: some View {
        List {
            ForEach(viewModel.clipboardItems) { item in
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Spacer()

                            Button(action: {
                                viewModel.toggleFavourite(for: item)
                            }) {
                                Image(systemName: item.isFavourite ? "star.fill" : "star")
                            }

                            Button(action: {
                                viewModel.removeClipboardItem(at: viewModel.clipboardItems.firstIndex(where: { $0.id == item.id })!)
                            }) {
                                Image(systemName: "trash")
                            }

                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(item.content, forType: .string)
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                        .padding()

                        Text(item.content)
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
        }
    }
}




