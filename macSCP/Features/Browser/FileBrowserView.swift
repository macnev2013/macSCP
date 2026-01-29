//
//  FileBrowserView.swift
//  macSCP
//
//  Main file browser view
//

import SwiftUI

struct FileBrowserView: View {
    @Bindable var viewModel: FileBrowserViewModel
    @Environment(\.openWindow) private var openWindow

    init(viewModel: FileBrowserViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            BrowserToolbar(viewModel: viewModel)

            Divider()

            // Breadcrumb
            BreadcrumbView(
                components: viewModel.pathComponents,
                onNavigate: { path in
                    Task {
                        await viewModel.navigateTo(path)
                    }
                }
            )

            Divider()

            // Content
            contentView

            Divider()

            // Status Bar
            statusBar
        }
        .frame(minWidth: WindowSize.minFileBrowser.width, minHeight: WindowSize.minFileBrowser.height)
        .task {
            await viewModel.connect()
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
        .sheet(isPresented: $viewModel.isShowingNewFileSheet) {
            NameInputSheet.newFile(
                onConfirm: { name in
                    Task {
                        await viewModel.createFile(name: name)
                    }
                },
                onCancel: {
                    viewModel.isShowingNewFileSheet = false
                }
            )
        }
        .sheet(isPresented: $viewModel.isShowingRenameSheet) {
            if let file = viewModel.fileToRename {
                NameInputSheet.rename(
                    currentName: file.name,
                    onConfirm: { newName in
                        Task {
                            await viewModel.renameFile(file, to: newName)
                        }
                    },
                    onCancel: {
                        viewModel.isShowingRenameSheet = false
                        viewModel.fileToRename = nil
                    }
                )
            }
        }
        .alert("Delete Files", isPresented: $viewModel.isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteFiles(viewModel.filesToDelete)
                }
            }
        } message: {
            let count = viewModel.filesToDelete.count
            Text("Are you sure you want to delete \(count) item\(count == 1 ? "" : "s")? This cannot be undone.")
        }
        .errorAlert($viewModel.error)
        .onChange(of: viewModel.pendingFileInfoWindowId) { _, windowId in
            if let windowId = windowId {
                openWindow(id: WindowID.fileInfo, value: windowId)
                viewModel.clearPendingFileInfoWindow()
            }
        }
        .onChange(of: viewModel.pendingEditorWindowId) { _, windowId in
            if let windowId = windowId {
                openWindow(id: WindowID.fileEditor, value: windowId)
                viewModel.clearPendingEditorWindow()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView(message: viewModel.isConnected ? "Loading..." : "Connecting...")

        case .success:
            if viewModel.sortedFiles.isEmpty {
                EmptyStateView.noFiles
            } else {
                FileListView(
                    viewModel: viewModel,
                    onOpenEditor: openFileInEditor,
                    onGetInfo: showFileInfo
                )
            }

        case .error(let error):
            ErrorView(error: error) {
                Task {
                    if viewModel.isConnected {
                        await viewModel.refresh()
                    } else {
                        await viewModel.connect()
                    }
                }
            }
        }
    }

    private var statusBar: some View {
        HStack {
            // Connection status
            HStack(spacing: 4) {
                Circle()
                    .fill(viewModel.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)

                Text(viewModel.isConnected ? viewModel.connection.connectionString : "Disconnected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Clipboard status
            if viewModel.hasClipboardItems {
                ClipboardStatusView(displayText: viewModel.clipboardDisplayText)
            }

            Spacer()

            // File count
            Text("\(viewModel.sortedFiles.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !viewModel.selectedFiles.isEmpty {
                Text("(\(viewModel.selectedFiles.count) selected)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.windowBackgroundColor))
    }

    private func openFileInEditor(_ file: RemoteFile) {
        Task {
            do {
                let content = try await viewModel.getFileContent(file)
                viewModel.openEditor(for: file, content: content)
            } catch {
                viewModel.error = AppError.from(error)
            }
        }
    }

    private func showFileInfo(_ file: RemoteFile) {
        viewModel.showFileInfo(file)
    }
}

// MARK: - Clipboard Status View
struct ClipboardStatusView: View {
    let displayText: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.on.clipboard")
                .font(.caption)
            Text(displayText)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(.secondary.opacity(0.1), in: Capsule())
    }
}

// MARK: - Preview
#Preview {
    FileBrowserView(
        viewModel: DependencyContainer.shared.makeFileBrowserViewModel(
            connection: Connection(name: "Test", host: "localhost", username: "user"),
            sftpSession: SFTPSession(),
            password: "test"
        )
    )
}
