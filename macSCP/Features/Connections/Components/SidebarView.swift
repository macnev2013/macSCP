//
//  SidebarView.swift
//  macSCP
//
//  Sidebar view for connection folders - Minimal macOS style
//

import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: ConnectionListViewModel
    @Environment(\.openURL) private var openURL

    private let gitHubIssuesURL = URL(string: "https://github.com/saxobrern/macSCP/issues")!

    // Check if All Connections is selected
    private var isAllConnectionsSelected: Bool {
        viewModel.selectedSidebarItem == .allConnections
    }

    // Check if a specific folder is selected
    private func isFolderSelected(_ folderId: UUID) -> Bool {
        if case .folder(let id) = viewModel.selectedSidebarItem {
            return id == folderId
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $viewModel.selectedSidebarItem) {
                // All Connections
                NavigationLink(value: SidebarSelection.allConnections) {
                    Label {
                        Text("All Connections")
                    } icon: {
                        Image(systemName: "server.rack")
                            .foregroundStyle(isAllConnectionsSelected ? .white : .blue)
                    }
                }

                // Folders Section
                Section("Folders") {
                    ForEach(viewModel.folders) { folder in
                        NavigationLink(value: SidebarSelection.folder(folder.id)) {
                            FolderRowView(
                                folder: folder,
                                connectionCount: viewModel.connectionCount(for: folder.id),
                                isSelected: isFolderSelected(folder.id),
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

            // Report Bug Card
            Button {
                openURL(gitHubIssuesURL)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Found a bug?")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.primary)
                        Text("Report it on GitHub")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(minWidth: 180)
    }
}

// MARK: - Folder Row
struct FolderRowView: View {
    let folder: Folder
    let connectionCount: Int
    let isSelected: Bool
    let onRename: (String) -> Void
    let onDelete: () -> Void

    @State private var isRenaming = false
    @State private var newName: String = ""

    var body: some View {
        Label {
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
        } icon: {
            Image(systemName: "folder.fill")
                .foregroundStyle(isSelected ? .white : .cyan)
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
