//
//  SidebarView.swift
//  macSCP
//
//  Sidebar view for connection folders
//

import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: ConnectionListViewModel

    var body: some View {
        List(selection: $viewModel.selectedSidebarItem) {
            // All Connections
            NavigationLink(value: SidebarSelection.allConnections) {
                Label {
                    HStack {
                        Text("All Connections")
                        Spacer()
                        BadgeView(count: viewModel.totalConnectionCount)
                    }
                } icon: {
                    Image(systemName: "server.rack")
                }
            }

            // Folders Section
            Section("Folders") {
                ForEach(viewModel.folders) { folder in
                    NavigationLink(value: SidebarSelection.folder(folder.id)) {
                        FolderRowView(
                            folder: folder,
                            connectionCount: viewModel.connectionCount(for: folder.id),
                            onRename: { newName in
                                Task {
                                    await viewModel.renameFolder(folder, to: newName)
                                }
                            },
                            onDelete: {
                                viewModel.confirmDeleteFolder(folder)
                            }
                        )
                    }
                }

                // New Folder Button
                Button {
                    viewModel.isShowingNewFolderSheet = true
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }
}

// MARK: - Folder Row
struct FolderRowView: View {
    let folder: Folder
    let connectionCount: Int
    let onRename: (String) -> Void
    let onDelete: () -> Void

    @State private var isRenaming = false
    @State private var newName: String = ""

    var body: some View {
        Label {
            HStack {
                if isRenaming {
                    TextField("Name", text: $newName)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            if !newName.trimmed.isEmpty {
                                onRename(newName.trimmed)
                            }
                            isRenaming = false
                        }
                        .onAppear {
                            newName = folder.name
                        }
                } else {
                    Text(folder.name)
                }

                Spacer()

                if connectionCount > 0 {
                    BadgeView(count: connectionCount)
                }
            }
        } icon: {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
        }
        .contextMenu {
            Button("Rename") {
                newName = folder.name
                isRenaming = true
            }

            Divider()

            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SidebarView(viewModel: DependencyContainer.shared.makeConnectionListViewModel())
        .frame(width: 250)
}
