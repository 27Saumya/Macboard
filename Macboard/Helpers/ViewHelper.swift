import SwiftUI
import Cocoa

struct LinkButtonStyle: ButtonStyle {
    
    @State var hover: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onHover { isHovering in
                self.hover = isHovering
                DispatchQueue.main.async {
                    if self.hover {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
    }
}

struct ItemButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        withAnimation(.easeInOut) {
            configuration.label
                .contentShape(Rectangle())
                .ignoresSafeArea()
        }
    }
}



struct ToastView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .padding(.all, 8)
                .background(.green)
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color.green)
                .cornerRadius(10)
                .frame(maxWidth: .infinity)
        }
        .background(colorScheme == .light ? .white.opacity(0.9) : .black.opacity(0.7))
    }
}


class MetadataViewModel: ObservableObject {
    @Published var metadata: [Metadata] = []
    
    func fetchMetadata(_ string: String) {
        guard let url = URL(string: string) else {
            return
        }
        metadata.removeAll()
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching webpage:", error ?? "Unknown error")
                return
            }
            
            if let htmlString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.parseMetadata(from: htmlString)
                }
            }
        }
        task.resume()
    }
        
    private func parseMetadata(from htmlString: String) {
        do {
            let regexTitle = try NSRegularExpression(pattern: "<meta[^>]*?property=['\"]og:title['\"][^>]*?content=['\"]([^'\"]*)['\"]", options: .caseInsensitive)
            let titleMatches = regexTitle.matches(in: htmlString, options: [], range: NSRange(location: 0, length: htmlString.utf16.count))
            
            let title = titleMatches.compactMap { match -> String? in
                guard match.numberOfRanges == 2 else { return nil }
                let valueRange = match.range(at: 1)
                if let value = Range(valueRange, in: htmlString) {
                    return String(htmlString[value])
                }
                return nil
            }.first ?? "Title Not Found"
            
            let regexDescription = try NSRegularExpression(pattern: "<meta[^>]*?property=['\"]og:description['\"][^>]*?content=['\"]([^'\"]*)['\"]", options: .caseInsensitive)
            let descriptionMatches = regexDescription.matches(in: htmlString, options: [], range: NSRange(location: 0, length: htmlString.utf16.count))
            
            let description = descriptionMatches.compactMap { match -> String? in
                guard match.numberOfRanges == 2 else { return nil }
                let valueRange = match.range(at: 1)
                if let value = Range(valueRange, in: htmlString) {
                    return String(htmlString[value])
                }
                return nil
            }.first ?? "Description Not Found"
            
            let regexImage = try NSRegularExpression(pattern: "<meta[^>]*?property=['\"]og:image['\"][^>]*?content=['\"]([^'\"]*)['\"]", options: .caseInsensitive)
            let imageMatches = regexImage.matches(in: htmlString, options: [], range: NSRange(location: 0, length: htmlString.utf16.count))
            
            let imageUrl = imageMatches.compactMap { match -> String? in
                guard match.numberOfRanges == 2 else { return nil }
                let valueRange = match.range(at: 1)
                if let value = Range(valueRange, in: htmlString) {
                    return String(htmlString[value])
                }
                return nil
            }.first ?? "Image URL Not Found"
            
            metadata.append(Metadata(key: "Title", value: title))
            metadata.append(Metadata(key: "Description", value: description))
            metadata.append(Metadata(key: "Image", value: imageUrl))
            
        } catch {
            print("Error parsing HTML:", error)
        }
    }
}


struct RemoteImage: View {
    let url: URL
    @State private var imageData: Data?
    
    var body: some View {
        Group {
            if let imageData = imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Image(systemName: "photo.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onAppear {
            fetchImage()
        }
    }
    
    private func fetchImage() {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching image:", error ?? "Unknown error")
                return
            }
            
            DispatchQueue.main.async {
                imageData = data
            }
        }.resume()
    }
}


struct CustomSplitView<Master: View, Detail: View>: View {
    let master: Master
    let detail: Detail
    
    init(@ViewBuilder master: () -> Master, @ViewBuilder detail: () -> Detail) {
        self.master = master()
        self.detail = detail()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                master
            }
            .frame(width: 300)
            
            Divider()
            
            VStack {
                detail
            }
            .frame(width: 400)
        }
    }
}
