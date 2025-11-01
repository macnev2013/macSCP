//
//  ConnectionListView.swift
//  macSCP
//
//  Main window showing folders and connections
//

import SwiftUI
import SwiftData

struct ConnectionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    @Query private var folders: [ConnectionFolder]
    @Query private var allConnections: [SSHConnection]
    @Query private var s3Connections: [S3Connection]

    enum SidebarSelection: Hashable {
        case all
        case folder(ConnectionFolder)
    }

    @State private var selection: SidebarSelection? = .all
    @State private var showingNewFolderSheet = false
    @State private var showingNewConnectionSheet = false
    @State private var showingNewS3ConnectionSheet = false
    @State private var showingDeleteFolderConfirmation = false
    @State private var folderToDelete: ConnectionFolder?
    @State private var newFolderName = ""

    var unorganizedConnections: [SSHConnection] {
        allConnections.filter { $0.folder == nil }
    }

    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            newFolderSheet
        }
        .sheet(isPresented: $showingNewConnectionSheet) {
            newConnectionSheet
        }
        .sheet(isPresented: $showingNewS3ConnectionSheet) {
            newS3ConnectionSheet
        }
        .alert("Delete Folder", isPresented: $showingDeleteFolderConfirmation, presenting: folderToDelete) { folder in
            deleteFolderAlertButtons(for: folder)
        } message: { folder in
            deleteFolderAlertMessage(for: folder)
        }
    }
    
    // MARK: - View Components
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                allConnectionsNavigationLink
                foldersSection
            }
            .navigationTitle("macSCP")
        }
    }
    
    private var allConnectionsNavigationLink: some View {
        NavigationLink(value: SidebarSelection.all) {
            HStack {
                Label("All", systemImage: "tray.full.fill")
                Spacer()
                Text("\(allConnections.count + s3Connections.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var foldersSection: some View {
        Section("Folders") {
            ForEach(folders) { folder in
                folderNavigationLink(for: folder)
            }
            
            addFolderButton
        }
    }
    
    private func folderNavigationLink(for folder: ConnectionFolder) -> some View {
        NavigationLink(value: SidebarSelection.folder(folder)) {
            HStack {
                Label(folder.name, systemImage: "folder.fill")
                Spacer()
                Text("\(folder.connections.count + folder.s3Connections.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contextMenu {
            Button(role: .destructive, action: {
                folderToDelete = folder
                showingDeleteFolderConfirmation = true
            }) {
                Label("Delete Folder", systemImage: "trash")
            }
        }
    }
    
    private var addFolderButton: some View {
        Button(action: { showingNewFolderSheet = true }) {
            Label("New Folder", systemImage: "plus.circle")
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .all:
            AllConnectionsView(allConnections: allConnections, s3Connections: s3Connections)
        case .folder(let folder):
            FolderContentView(folder: folder)
        case .none:
            NoFolderSelectedView(onCreateFolder: { showingNewFolderSheet = true })
        }
    }
    
    private var newFolderSheet: some View {
        NewFolderView(folderName: $newFolderName, onCreate: {
            createFolder()
        })
    }
    
    @ViewBuilder
    private var newConnectionSheet: some View {
        if case .folder(let folder) = selection {
            NewSSHConnectionSheetView(folder: folder)
        } else {
            NewSSHConnectionSheetView(folder: nil)
        }
    }
    
    @ViewBuilder
    private var newS3ConnectionSheet: some View {
        if case .folder(let folder) = selection {
            NewS3ConnectionSheetView(folder: folder)
        } else {
            NewS3ConnectionSheetView(folder: nil)
        }
    }
    
    @ViewBuilder
    private func deleteFolderAlertButtons(for folder: ConnectionFolder) -> some View {
        Button("Cancel", role: .cancel) {
            folderToDelete = nil
        }

        if !folder.connections.isEmpty {
            Button("Keep Connections", role: .none) {
                deleteFolderOnly(folder)
            }
            Button("Delete All", role: .destructive) {
                deleteFolderAndConnections(folder)
            }
        } else {
            Button("Delete Folder", role: .destructive) {
                deleteFolderOnly(folder)
            }
        }
    }
    
    private func deleteFolderAlertMessage(for folder: ConnectionFolder) -> Text {
        if folder.connections.isEmpty {
            return Text("Are you sure you want to delete '\(folder.name)'?")
        } else {
            return Text("The folder '\(folder.name)' contains \(folder.connections.count) connection(s). Do you want to keep the connections or delete everything?")
        }
    }

    private func createFolder() {
        guard !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let folder = ConnectionFolder(name: newFolderName.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(folder)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save folder: \(error)")
        }

        newFolderName = ""
        showingNewFolderSheet = false
        selection = .folder(folder)
    }

    private func deleteFolderOnly(_ folder: ConnectionFolder) {
        withAnimation {
            // Move all connections to no folder (unorganized)
            for connection in folder.connections {
                connection.folder = nil
            }

            // Delete just the folder
            modelContext.delete(folder)

            // Clear selection if we're deleting the selected folder
            if case .folder(let selectedFolder) = selection, selectedFolder.id == folder.id {
                selection = .all
            }

            folderToDelete = nil
        }
    }

    private func deleteFolderAndConnections(_ folder: ConnectionFolder) {
        withAnimation {
            // Delete all saved passwords for connections in this folder
            for connection in folder.connections {
                if connection.shouldSavePassword {
                    _ = KeychainManager.shared.deletePassword(for: connection.id.uuidString)
                }
            }

            // Delete the folder (SwiftData will cascade delete connections)
            modelContext.delete(folder)

            // Clear selection if we're deleting the selected folder
            if case .folder(let selectedFolder) = selection, selectedFolder.id == folder.id {
                selection = .all
            }

            folderToDelete = nil
        }
    }
}

// MARK: - No Folder Selected
struct NoFolderSelectedView: View {
    let onCreateFolder: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("No Folder Selected")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create a folder to organize your SSH connections")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: onCreateFolder) {
                Label("Create New Folder", systemImage: "plus.circle.fill")
                    .font(.body)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ConnectionListView()
        .modelContainer(for: [ConnectionFolder.self, SSHConnection.self, S3Connection.self], inMemory: true)
}
