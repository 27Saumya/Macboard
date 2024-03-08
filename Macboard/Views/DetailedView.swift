import SwiftUI
import Defaults
import KeyboardShortcuts

struct DetailedView: View {
    
    let clipboardItem: ClipboardItem
    
    @Default(.showUrlMetadata) var showUrlMetadata
    
    @ObservedObject var vm: MetadataViewModel
    @Binding var selectedItem: ClipboardItem?
    
    @State private var hover: Bool = false
    
    var body: some View {
        if selectedItem != nil {
            VStack {
                if clipboardItem.contentType == "Text" || clipboardItem.contentType == "File" {
                    List {
                        Section {
                            if clipboardItem.contentType == "Text" && clipboardItem.content!.isValidURL && showUrlMetadata {
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
                                if clipboardItem.contentType == "Text" && clipboardItem.content!.isValidURL {
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
                                } else {
                                    Text(clipboardItem.content!)
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
                            }
                        } header: {
                            HStack {
                                if clipboardItem.content!.isValidURL && showUrlMetadata {
                                    Image(systemName: "photo.fill")
                                    Text("Meta Image")
                                } else if clipboardItem.contentType == "String" {
                                    Image(systemName: "doc.circle.fill")
                                    Text("Complete File Path")
                                } else {
                                    Image(systemName: "doc.plaintext.fill")
                                    Text("Complete Text")
                                }
                            }
                        }
                        
                        if clipboardItem.contentType == "Text" && clipboardItem.content!.isValidURL && showUrlMetadata {
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
                                    if clipboardItem.contentType == "File" {
                                        Text("File")
                                    } else if clipboardItem.content!.contains("\n") {
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
                    .padding(.bottom, -8)
                    
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
                    .padding(.bottom, -8)
                }
                
                Divider()
                
                HStack {
                    Text("Paste:")
                        .font(.footnote)
                    if let shortcut = KeyboardShortcuts.Name("paste").shortcut {
                        Text(shortcutToText(shortcut))
                            .font(.footnote)
                            .opacity(0.8)
                    } else {
                        Text("↩")
                            .font(.footnote)
                            .opacity(0.8)
                    }
                    CustomDivider()
                    Text("Copy & Hide:")
                        .font(.footnote)
                    if let shortcut = KeyboardShortcuts.Name("copyAndHide").shortcut {
                        Text(shortcutToText(shortcut))
                            .font(.footnote)
                            .opacity(0.8)
                    } else {
                        Text("⌘ ↩")
                            .font(.footnote)
                            .opacity(0.8)
                    }
                    CustomDivider()
                    Text(clipboardItem.isPinned ? "Unpin:" : "Pin:")
                        .font(.footnote)
                    if let shortcut = KeyboardShortcuts.Name("togglePin").shortcut {
                        Text(shortcutToText(shortcut))
                            .font(.footnote)
                            .opacity(0.8)
                    } else {
                        Text("⌘ P")
                            .font(.footnote)
                            .opacity(0.8)
                    }
                    CustomDivider()
                    Text("Delete:")
                        .font(.footnote)
                    if let shortcut = KeyboardShortcuts.Name("deleteItem").shortcut {
                        Text(shortcutToText(shortcut))
                            .font(.footnote)
                            .opacity(0.8)
                    } else {
                        Text("⌫")
                            .font(.footnote)
                            .opacity(0.8)
                    }
                }
                .padding(.top, -8)
                .frame(maxWidth: .infinity, minHeight: 18, idealHeight: 18, maxHeight: 18)
            }
        } else {
            Text("Select an item to get its detailed view")
                .bold()
                .padding()
        }
    }
}
