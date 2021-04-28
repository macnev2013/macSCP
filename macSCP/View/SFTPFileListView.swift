//
//  SFTPFileListView.swift
//  macSCP
//
//  Created by Nevil Macwan on 27/04/21.
//

import SwiftUI
import NMSSH

struct SFTPFileListView: View {
    @Environment(\.colorScheme) var colorScheme

    var session: NMSSHSession
    var queue = DispatchQueue(label: "listFiles")
    
    @State var sftpSession: NMSFTP?
    @State var selectedItem: NMSFTPFile?
    @State var directories: [NMSFTPFile] = []
    @State var currentPath = "/"
    @State var routeToPath = ""
    @State var pathHistory: [String] = []
    @State private var isDefaultItemActive = true
    @State private var showingCreateNewFolderSheet = false
    
    func updateDirectoryList () {
        self.queue.async {
            directories = getFileList(session: sftpSession!, dir: currentPath)
        }
    }

    var backButton: some View {
        Button(action: {
            if pathHistory.count > 0 {
                currentPath = pathHistory.popLast() ?? ""
                updateDirectoryList()
            }
        }) {
            Image(systemName: "chevron.left")
        }
    }
    
    var refreshButton: some View {
        Button(action: {
            updateDirectoryList()
        }) {
            Image(systemName: "arrow.clockwise.circle")
        }
    }
    
    var deleteFilesButton: some View {
        Button(action: {
            let selectedFilename = self.selectedItem?.filename ?? ""
            if !selectedFilename.isEmpty {
                let pathToDelete = currentPath + selectedFilename
                deleteDirectoy(session: sftpSession!, atPath: pathToDelete)
                updateDirectoryList()
            }
        }, label: {
            Text("Delete")
            Image(systemName: "trash")
        })
        .buttonStyle(PlainButtonStyle())
    }
    
    var downloadFileButton: some View {
        Button(action: {
            let selectedFilename = self.selectedItem?.filename ?? ""
            if !selectedFilename.isEmpty {
                let pathToDownload = currentPath + selectedFilename
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                if panel.runModal() == .OK {
                    let downloadDirectory = panel.url?.path ?? "<none>"
                    
                    print("Downloading file \(pathToDownload) to \(downloadDirectory)")
                }
            }
        }, label: {
            Text("Download")
            Image(systemName: "square.and.arrow.down.fill")
        })
        .buttonStyle(PlainButtonStyle())
    }
    
    var makeDirectoyButton: some View {
        Button(action: {
            showingCreateNewFolderSheet.toggle()
            updateDirectoryList()
        }, label: {
            Text("Make Folder")
            Image(systemName: "plus.rectangle.fill.on.folder.fill")
        })
        .buttonStyle(PlainButtonStyle())
    }
    
    var goButton: some View {
        Button(action: {
            if currentPath != routeToPath {
                currentPath = routeToPath
                updateDirectoryList()
            }
        }, label: {
            Image(systemName: "chevron.right.circle")
        })
    }
    
    
    var body: some View {

        VStack {
            HStack {
                Picker(selection: $routeToPath, label: Text("Directory:")) {
                    ForEach(pathHistory, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                Spacer()
                self.goButton
            }
            .padding(.horizontal)
        
            
            List(directories, id: \.self, selection: $selectedItem) { directory in
                ConnectionDirView(directory: directory)
                    .frame(minWidth: 30, idealWidth: 30, maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        self.selectedItem = Optional(directory)
                        if (self.selectedItem?.filename != nil) {
                            currentPath = "\(currentPath)\(self.selectedItem?.filename ?? "")"
                            updateDirectoryList()
                            routeToPath = currentPath
                            if !pathHistory.contains(currentPath) {
                                pathHistory.append(currentPath)
                            }
                        }
                    }
                    .onTapGesture(count: 1) {
                        self.selectedItem = Optional(directory)
                    }
            }
            .contextMenu(ContextMenu(menuItems: {
                self.makeDirectoyButton
                self.downloadFileButton
                self.deleteFilesButton
            }))
            .frame(minWidth: 30, idealWidth: 30, maxWidth: .infinity)
            .onAppear {
                self.sftpSession = createSFTPSession(session: session)
                if !pathHistory.contains(currentPath) {
                    pathHistory.append(currentPath)
                }
                routeToPath = currentPath
                updateDirectoryList()
            }
            .toolbar {
                ToolbarItemGroup {
                    self.backButton
                    Spacer()
                    self.refreshButton
                    Menu {
                        self.makeDirectoyButton
                    } label: {
                         Image(systemName: "ellipsis.circle")
                    }
                    .sheet(isPresented: $showingCreateNewFolderSheet) { CreateNewDirectoryView(sftpSession: self.sftpSession!, directory: currentPath) }
                }
            }
        }
    }
}

struct SFTPFileListView_Previews: PreviewProvider {
    static var previews: some View {
        SFTPFileListView(session: NMSSHSession(host: "test", andUsername: "username"), selectedItem: NMSFTPFile(filename: "newfilename"))
    }
}
