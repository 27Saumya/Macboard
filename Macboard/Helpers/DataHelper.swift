import Foundation
import SwiftUI
import CoreData

struct Metadata {
    let key: String
    let value: String
}

struct CoreDataManager {
    func addToClipboard(content: String? = nil, 
                        imageData: Data? = nil,
                        contentType: String,
                        sourceApp: String,
                        context: NSManagedObjectContext) {
        
        let newItem = ClipboardItem(context: context)
        newItem.id = UUID()
        newItem.createdAt = Date.now
        newItem.content = content
        newItem.imageData = imageData
        newItem.contentType = contentType
        newItem.sourceApp = sourceApp
        
        PersistanceController.shared.save()
    }
    
    func isReCopied(item: ClipboardItem) {
        item.createdAt = Date.now
        
        PersistanceController.shared.save()
    }
    
    func deleteItem(item: ClipboardItem) {
        guard let context = item.managedObjectContext else { return }
        
        context.delete(item)
        PersistanceController.shared.save()
    }
    
    func togglePin(for item: ClipboardItem) {
        item.isPinned.toggle()
        
        PersistanceController.shared.save()
    }
    
    func clearClipboard() {
        let context = PersistanceController.shared.container.viewContext
        do {
            let fetchRequest = ClipboardItem.fetchRequest()
            let items = try context.fetch(fetchRequest)
            for item in items {
                context.delete(item)
            }
        } catch {
            print("Failed to clear the clipboard")
        }
    }
}
