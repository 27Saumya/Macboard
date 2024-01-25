import Foundation
import SwiftUI
import Cocoa
import LinkPresentation

func dataToImage(_ value: Data) -> (Image, String) {
    let image = NSImage(data: value)
    return (Image(nsImage: image!) , image?.name()! ?? "image.png")
}

func extractMetadata(from url: URL) async -> LPLinkMetadata? {
    let metadataProvider = LPMetadataProvider()
    
    do {
        let metadata = try await metadataProvider.startFetchingMetadata(for: url)
        
        let title = metadata.title
        let description = metadata.value(forKey: "_summary") as? String
        let hostName = url.host
        
        // Get URL Image
        _ = metadata.imageProvider?.loadDataRepresentation(for: .image) { imageData, error in
            if let imageData = imageData {
                // We now have access to the URL's image by using NSItemProvider to load the image object
                let uiImage = NSImage(data: imageData)
            }
        }
        
        // Get URL Logo
        _ = metadata.iconProvider?.loadDataRepresentation(for: .image) { imageData, error in
            if let imageData = imageData {
                // We now have access to the URL's icon by using NSItemProvider to load the image object
                let uiImage = NSImage(data: imageData)
            }
        }
        
        return metadata
    } catch {
        print("Failed to get metadata for URL: \(error.localizedDescription)")
    }
    return nil
}
