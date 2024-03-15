import SwiftUI
import Settings
import Defaults

struct StorageSettingsView: View {
    
    @Default(.allowedTypes) var allowedTypes
    @Default(.maxItems) var maxItems
    @Default(.clearPins) var clearPins
    
    @State var textAllowed: Bool = Bool()
    @State var imageAllowed: Bool = Bool()
    @State var fileAllowed: Bool = Bool()
    
    var body: some View {
        Settings.Container(contentWidth: 350) {
            Settings.Section(title: "") {
                VStack(alignment: .leading) {
                    Toggle("Clear pins while clearing clipboard", isOn: $clearPins)
                    Divider()
                        .padding(.vertical, 2)
                    Toggle("Save Text", isOn: $textAllowed)
                        .onAppear {
                            textAllowed = allowedTypes.contains("Text")
                        }
                        .onChange(of: textAllowed) { newValue in
                            if newValue == true {
                                if !allowedTypes.contains("Text") {
                                    allowedTypes.append("Text")
                                }
                            } else {
                                if let index = allowedTypes.firstIndex(of: "Text") {
                                    allowedTypes.remove(at: index)
                                }
                            }
                        }
                    Toggle("Save Images", isOn: $imageAllowed)
                        .onAppear {
                            imageAllowed = allowedTypes.contains("Image")
                        }
                        .onChange(of: imageAllowed) { newValue in
                            if newValue == true {
                                if !allowedTypes.contains("Image") {
                                    allowedTypes.append("Image")
                                }
                            } else {
                                if let index = allowedTypes.firstIndex(of: "Image") {
                                    allowedTypes.remove(at: index)
                                }
                            }
                        }
                    Toggle("Save Files", isOn: $fileAllowed)
                        .onAppear {
                            fileAllowed = allowedTypes.contains("File")
                        }
                        .onChange(of: fileAllowed) { newValue in
                            if newValue == true {
                                if !allowedTypes.contains("File") {
                                    allowedTypes.append("File")
                                }
                            } else {
                                if let index = allowedTypes.firstIndex(of: "File") {
                                    allowedTypes.remove(at: index)
                                }
                            }
                        }
                    Text("Customise what type of content should be saved and displayed")
                        .font(.footnote)
                        .opacity(0.7)
                        .padding(.top, 2)
                    Divider()
                        .padding(.top, 2)
                        .padding(.bottom, 6)
                    HStack {
                        Text("Maximum Items")
                        TextField("", value: $maxItems, formatter: NumberFormatter())
                            .frame(width: 75)
                        Stepper(value: $maxItems) {
                            
                        }
                    }
                    Text("0 for unlimited")
                        .font(.footnote)
                        .opacity(0.7)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.leading, -51)
                }
            }
        }
    }
}

