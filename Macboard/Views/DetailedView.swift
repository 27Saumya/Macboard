import SwiftUI

struct DetailedView: View {
    
    let clipboardItem: ClipboardItem
    @ObservedObject var vm: MetadataViewModel
    
    @State private var hover: Bool = false
    
    var body: some View {
        VStack {
            if clipboardItem.contentType == "Text" {
                List {
                    Section {
                        if clipboardItem.content!.isValidURL {
                            let imageURLString = vm.metadata.first(where: {$0.key == "Image"})?.value
                            if imageURLString != nil {
                                if imageURLString != "Not Found" {
                                    let imageURL = URL(string: imageURLString!)!
                                    RemoteImage(url: imageURL)
                                } else {
                                    Image(systemName: "photo.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
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
                                Image(systemName: "person.badge.clock.fill")
                                Text("Copied:")
                                Spacer()
                                Text(clipboardItem.createdAt!.timeAgoDisplay())
                            }
                            
                            HStack {
                                Image(systemName: "link")
                                Text("URL:")
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
                            
                            if let title = vm.metadata.first(where: {$0.key == "Title"})?.value {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Title:")
                                    Spacer()
                                    Text(title)
                                }
                            }
                            
                            if let description = vm.metadata.first(where: {$0.key == "Description"})?.value {
                                HStack {
                                    Image(systemName: "note.text")
                                    Text("Description:")
                                    Spacer()
                                    Text(description)
                                }
                            }
                            
                            HStack {
                                Image(systemName: "app.badge.checkmark.fill")
                                Text("Source App:")
                                Spacer()
                                Text(clipboardItem.sourceApp ?? "Unknown")
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
                                Text("Copied:")
                                Spacer()
                                Text(clipboardItem.createdAt!.timeAgoDisplay())
                            }
                            
                            HStack {
                                Image(systemName: "note.text")
                                Text("Type:")
                                Spacer()
                                if clipboardItem.content!.contains("\n") {
                                    Text("Multi-line Text")
                                } else if clipboardItem.content!.isNum {
                                    Text("Number")
                                } else {
                                    Text("RTF - Rich Text Format")
                                }
                            }
                            
                            HStack {
                                Image(systemName: "app.badge.checkmark.fill")
                                Text("Source App:")
                                Spacer()
                                Text(clipboardItem.sourceApp ?? "Unknown")
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
                            Text("Copied:")
                            Spacer()
                            Text(clipboardItem.createdAt!.timeAgoDisplay())
                        }
                        
                        HStack {
                            Image(systemName: "photo.fill")
                            Text("Type:")
                            Spacer()
                            Text("TIFF Image")
                        }
                        
                        HStack {
                            Image(systemName: "app.badge.checkmark.fill")
                            Text("Source App:")
                            Spacer()
                            Text(clipboardItem.sourceApp ?? "Unknown")
                        }
                        
                    } header: {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text("Details")
                        }
                    }
                }
            }
        }
    }
}
