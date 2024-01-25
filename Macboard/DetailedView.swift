import SwiftUI
import LinkPresentation

struct DetailedView: View {
    
    let clipboardItem: ClipboardItem
    
    @State private var hover: Bool = false
    @State private var metaImage: Image?
    @State private var metaData: [String: String?]
    
    var body: some View {
        VStack {
            if clipboardItem.contentType == .text {
                List {
                    Section {
                        if clipboardItem.content!.isValidURL {
                            if let metaImage = metaImage {
                                metaImage
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
                        } else {
                            Text(clipboardItem.content!)
                                .textFieldStyle(.roundedBorder)
                                .textSelection(.enabled)
                                .onHover(perform: { isHovering in
                                    self.hover = isHovering
                                    DispatchQueue.main.async {
                                        if self.hover {
                                            NSCursor.iBeam.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                                })
                        }
                    } header: {
                        HStack {
                            if clipboardItem.content!.isValidURL {
                                Image(systemName: "photo.fill")
                                Text("Meta Image")
                            } else {
                                Image(systemName: "doc.plaintext.fill")
                                Text("Complete Text")
                            }
                        }
                    }
                    
                    if clipboardItem.content!.isValidURL {
                        Section {
                            HStack {
                                Image(systemName: "link")
                                Text("URL")
                                Spacer()
                                Link(clipboardItem.content!, destination: URL(string: clipboardItem.content!)!)
                                    .textFieldStyle(.roundedBorder)
                                    .textSelection(.enabled)
                                    .onHover(perform: { isHovering in
                                        self.hover = isHovering
                                        DispatchQueue.main.async {
                                            if self.hover {
                                                NSCursor.pointingHand.push()
                                            } else {
                                                NSCursor.pop()
                                            }
                                        }
                                    })
                            }
                            
                            HStack {
                                Image(systemName: "pencil")
                                Text("Title")
                                Spacer()
                            }
                            
                        } header: {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text("URL Details")
                            }
                        }
                        
                    } else {
                        Section {
                            HStack {
                                Image(systemName: "person.badge.clock.fill")
                                Text("Copied")
                                Spacer()
                                Text(clipboardItem.createdAt.timeAgoDisplay())
                            }
                            
                            HStack {
                                Image(systemName: "note.text")
                                Text("Type")
                                Spacer()
                                if clipboardItem.content!.contains("\n") {
                                    Text("Multi-line Text")
                                } else if clipboardItem.content!.isValidURL {
                                    Text("URL")
                                } else if clipboardItem.content!.isNum {
                                    Text("Number")
                                } else {
                                    Text("RTF - Rich Text Format")
                                }
                            }
                            
                        } header: {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text("Details")
                            }
                        }
                    }
                }
                
            } else {
                List {
                    Section {
                        let image = dataToImage(clipboardItem.imageData!)
                        image.0
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .scaledToFit()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } header: {
                        HStack {
                            Image(systemName: "photo.fill")
                            Text("Image")
                        }
                    }
                    
                    Section {
                        HStack {
                            Image(systemName: "person.badge.clock.fill")
                            Text("Copied")
                            Spacer()
                            Text(clipboardItem.createdAt.timeAgoDisplay())
                        }
                        
                        HStack {
                            Image(systemName: "photo.fill")
                            Text("Type")
                            Spacer()
                            Text("TIFF Image")
                        }
                    } header: {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text("Details")
                        }
                    }
                }
            }
        }.task {
            await fetchMetadata(content: clipboardItem.content ?? nil)
        }
    }
    
    private func fetchMetadata(content: String?) async {
        if content != nil {
            if content!.isValidURL {
                let url = URL(string: content!)
                if url != nil {
                    let _metaData = await extractMetadata(from: url!)
                    metaData = ["Title": _metaData?.title,
                                "Description": _metaData?.value(forKey: "_summary") as? String,
                                "HostName": url!.host]
                    _ = _metaData?.imageProvider?.loadDataRepresentation(for: .image) { imageData, error in
                        if let imageData = imageData {
                            let nsImage = NSImage(data: imageData)
                            if nsImage != nil {
                                metaImage = Image(nsImage: nsImage!)
                            } else {
                                metaImage = nil
                            }
                        }
                    }
                }
            }
        }
    }
}
