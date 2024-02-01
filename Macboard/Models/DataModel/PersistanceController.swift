import Foundation
import CoreData

struct PersistanceController {
    
    static let shared = PersistanceController()
    
    let container: NSPersistentContainer
    
    init() {
        self.container = NSPersistentContainer(name: "ClipboardItem")
        
        container.loadPersistentStores { desc, error in
            if let error = error as NSError? {
                fatalError("Error loading container: \(error), \(error.userInfo)")
            }
        }
    }
    
    func save() {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save the data")
        }
    }
}
