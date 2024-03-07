import Cocoa
import SwiftUI
import Defaults

enum MenubarIcon: String, CaseIterable, Identifiable, Defaults.Serializable {
    case normal = "doc.on.clipboard"
    case fill = "doc.on.clipboard.fill"
    case clip = "paperclip"
    case scissors = "scissors"
    
    var id: Self { self }
}

enum SearchType: String, CaseIterable, Identifiable, Defaults.Serializable {
    case sensitive = "Case Sensitive"
    case insensitive = "Case Insensitive"
    
    var id: Self { self }
}

struct Metadata {
    let key: String
    let value: String
}

struct CoreDataManager {
    func addToClipboard(content: String? = nil,
                        imageData: Data? = nil,
                        fileURL: URL? = nil,
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
