//
//  ConnectionListView.swift
//  macSCP
//
//  Main view for managing SSH connections
//

import SwiftUI

struct ConnectionListView: View {
    @Bindable var viewModel: ConnectionListViewModel
    @Environment(\.openWindow) private var openWindow

    init(viewModel: ConnectionListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            ConnectionGridView(viewModel: viewModel)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.isShowingNewConnectionSheet = true
                } label: {
                    Label("New Connection", systemImage: "plus")
                }

                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search connections")
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.isShowingNewConnectionSheet) {
            ConnectionFormSheet(
                mode: .create,
                folders: viewModel.folders,
                onSave: { connection, password in
                    Task {
                        await viewModel.saveConnection(connection, password: password)
                    }
                },
                onCancel: {
                    viewModel.isShowingNewConnectionSheet = false
                }
            )
        }
        .sheet(isPresented: $viewModel.isShowingEditConnectionSheet) {
            if let connection = viewModel.connectionToEdit {
                ConnectionFormSheet(
                    mode: .edit(connection),
                    savedPassword: viewModel.getSavedPassword(for: connection),
                    folders: viewModel.folders,
                    onSave: { updatedConnection, password in
                        Task {
                            await viewModel.updateConnection(updatedConnection, password: password)
                        }
                    },
                    onCancel: {
                        viewModel.isShowingEditConnectionSheet = false
                        viewModel.connectionToEdit = nil
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.isShowingNewFolderSheet) {
            NameInputSheet.newFolder(
                onConfirm: { name in
                    Task {
                        await viewModel.createFolder(name: name)
                    }
                },
                onCancel: {
                    viewModel.isShowingNewFolderSheet = false
                }
            )
        }
        .sheet(isPresented: $viewModel.isShowingPasswordPrompt) {
            if let connection = viewModel.connectionToConnect {
                PasswordPromptSheet(
                    connectionName: connection.name,
                    onConnect: { password in
                        viewModel.connectWithPassword(password)
                    },
                    onCancel: {
                        viewModel.cancelConnect()
                    }
                )
            }
        }
        .alert("Delete Folder", isPresented: $viewModel.isShowingDeleteFolderAlert) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelDeleteFolder()
            }
            Button("Delete", role: .destructive) {
                if let folder = viewModel.folderToDelete {
                    Task {
                        await viewModel.deleteFolder(folder)
                    }
                }
            }
        } message: {
            if let folder = viewModel.folderToDelete {
                let count = viewModel.connectionCount(for: folder.id)
                Text("Are you sure you want to delete \"\(folder.name)\"? \(count > 0 ? "The \(count) connection(s) in this folder will be moved to All Connections." : "")")
            }
        }
        .errorAlert($viewModel.error)
        .onChange(of: viewModel.pendingWindowId) { _, windowId in
            if let windowId = windowId {
                logInfo("Opening file browser window with ID: \(windowId)", category: .ui)
                openWindow(id: WindowID.fileBrowser, value: windowId)
                viewModel.clearPendingWindow()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ConnectionListView(viewModel: DependencyContainer.shared.makeConnectionListViewModel())
}
