//
//  ClipboardManagerView.swift
//  Macboard
//
//  Created by Saumya Patel on 20/01/24.
//

import Foundation
import Cocoa

class ClipboardManagerViewModel: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []

    private var clipboardChangeTimer: Timer?

    init() {
        clipboardChangeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }

        checkClipboard()
    }

    deinit {
        clipboardChangeTimer?.invalidate()
    }

    private func checkClipboard() {
        guard let content = NSPasteboard.general.string(forType: .string), !content.isEmpty else {
            return
        }

        if clipboardItems.firstIndex(where: { $0.content == content }) == nil {
            let newItem = ClipboardItem(content: content, timestamp: Date())
            clipboardItems.insert(newItem, at: 0)
        }
    }

    func clearClipboard() {
        clipboardItems.removeAll()
    }

    func removeClipboardItem(at index: Int) {
        guard index >= 0, index < clipboardItems.count else { return }
        clipboardItems.remove(at: index)
    }

    func toggleFavourite(for item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems[index].isFavourite.toggle()
        }
    }
}



