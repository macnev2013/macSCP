//
//  FileListView.swift
//  macSCP
//
//  List view for displaying files in the browser
//

import SwiftUI

struct FileListView: View {
    @Bindable var viewModel: FileBrowserViewModel
    let onOpenEditor: (RemoteFile) -> Void
    let onGetInfo: (RemoteFile) -> Void

    var body: some View {
        List(selection: $viewModel.selectedFiles) {
            ForEach(viewModel.sortedFiles) { file in
                FileRowView(
                    file: file,
                    isSelected: viewModel.selectedFiles.contains(file.id),
                    onDoubleClick: {
                        Task {
                            if file.isDirectory {
                                await viewModel.navigateTo(file.path)
                            } else if FileTypeService.isPreviewable(file) {
                                onOpenEditor(file)
                            }
                        }
                    }
                )
                .tag(file.id)
                .contextMenu {
                    fileContextMenu(for: file)
                }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    @ViewBuilder
    private func fileContextMenu(for file: RemoteFile) -> some View {
        if file.isFile {
            Button("Open in Editor") {
                onOpenEditor(file)
            }

            Divider()
        }

        Button("Copy") {
            viewModel.selectedFiles = [file.id]
            viewModel.copySelectedFiles()
        }

        Button("Cut") {
            viewModel.selectedFiles = [file.id]
            viewModel.cutSelectedFiles()
        }

        if viewModel.canPaste {
            Button("Paste") {
                Task {
                    await viewModel.paste()
                }
            }
        }

        Divider()

        Button("Rename") {
            viewModel.startRename(file)
        }

        Button("Get Info") {
            onGetInfo(file)
        }

        Divider()

        if file.isFile {
            Button("Download") {
                Task {
                    await viewModel.downloadFile(file)
                }
            }
        }

        Divider()

        Button("Delete", role: .destructive) {
            viewModel.confirmDelete([file])
        }
    }
}

// MARK: - Preview
#Preview {
    FileListView(
        viewModel: DependencyContainer.shared.makeFileBrowserViewModel(
            connection: Connection(name: "Test", host: "localhost", username: "user"),
            sftpSession: SFTPSession(),
            password: "test"
        ),
        onOpenEditor: { _ in },
        onGetInfo: { _ in }
    )
}
