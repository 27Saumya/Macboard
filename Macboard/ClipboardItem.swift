//
//  ClipboardItems.swift
//  Macboard
//
//  Created by Saumya Patel on 20/01/24.
//

import Foundation

struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: Date
    var isFavourite: Bool = false
}
