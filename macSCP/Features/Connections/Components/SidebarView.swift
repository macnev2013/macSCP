//
//  SidebarView.swift
//  macSCP
//
//  Sidebar view for connection folders - Modern macOS style
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
                            .fontWeight(.medium)
                        Spacer()
                        if viewModel.totalConnectionCount > 0 {
                            Text("\(viewModel.totalConnectionCount)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                } icon: {
                    Image(systemName: "server.rack")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                }
            }

            // Folders Section
            Section {
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
                    Label {
                        Text("New Folder")
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "folder.badge.plus")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Folders")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
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
    @State private var isHovering = false

    var body: some View {
        Label {
            HStack {
                if isRenaming {
                    TextField("Name", text: $newName)
                        .textFieldStyle(.plain)
                        .font(.body)
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
                        .fontWeight(.medium)
                }

                Spacer()

                if connectionCount > 0 {
                    Text("\(connectionCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
            }
        } icon: {
            ZStack {
                Image(systemName: "folder.fill")
                    .font(.body)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isHovering ? .blue : .cyan)
            }
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button {
                newName = folder.name
                isRenaming = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SidebarView(viewModel: DependencyContainer.shared.makeConnectionListViewModel())
        .frame(width: 250)
}
