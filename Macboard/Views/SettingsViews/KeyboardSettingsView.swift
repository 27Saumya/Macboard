import SwiftUI
import Settings
import KeyboardShortcuts

struct KeyboardSettingsView: View {
    
    var body: some View {
        Settings.Container(contentWidth: 450) {
            Settings.Section(title: "") {
                VStack(alignment: .center) {
                    Form {
                        HStack {
                            KeyboardShortcuts.Recorder("Toggle Macboard:", name: .toggleMacboard)
                            Button {
                                KeyboardShortcuts.Name("toggleMacboard").shortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.shift, .command])
                            } label: {
                                Text("Reset")
                                    .font(.footnote)
                            }
                        }
                        .padding(.leading, -12)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    Divider()
                        .padding(.vertical, 4)
                    Form {
                        HStack {
                            KeyboardShortcuts.Recorder("Clear Clipboard:", name: .clearClipboard)
                            Button {
                                KeyboardShortcuts.Name("clearClipboard").shortcut = KeyboardShortcuts.Shortcut(.delete, modifiers: [.command])
                            } label: {
                                Text("Reset")
                                    .font(.footnote)
                            }
                        }
                        HStack {
                            KeyboardShortcuts.Recorder("Paste:", name: .paste)
                            Button {
                                KeyboardShortcuts.Name("paste").shortcut = KeyboardShortcuts.Shortcut(.return, modifiers: [])
                            } label: {
                                Text("Reset")
                                    .font(.footnote)
                            }
                        }
                        HStack {
                            KeyboardShortcuts.Recorder("Copy:", name: .copyItem)
                            Button {
                                KeyboardShortcuts.Name("copyItem").shortcut = KeyboardShortcuts.Shortcut(.return, modifiers: [.command])
                            } label: {
                                Text("Reset")
                                    .font(.footnote)
                            }
                        }
                        HStack {
                            KeyboardShortcuts.Recorder("Toggle Pin:", name: .togglePin)
                            Button {
                                KeyboardShortcuts.Name("togglePin").shortcut = KeyboardShortcuts.Shortcut(.p, modifiers: [.command])
                            } label: {
                                Text("Reset")
                                    .font(.footnote)
                            }
                        }
                        HStack {
                            KeyboardShortcuts.Recorder("Delete Item:", name: .deleteItem)
                            Button {
                                KeyboardShortcuts.Name("deleteItem").shortcut = KeyboardShortcuts.Shortcut(.delete, modifiers: [])
                            } label: {
                                Text("Reset")
                                    .font(.footnote)
                            }
                        }
                    }
                    Text("Custom keyboard shortcuts require a re-launch to get reflected")
                        .padding(.top, 6)
                        .opacity(0.8)
                        .font(.footnote)
                    Button {
                        relaunch()
                    } label: {
                        Text("Relaunch Now")
                            .font(.footnote)
                    }
                    .padding(.top, 2)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}
