//
//  FileListView.swift
//  macSCP
//
//  List view for displaying files in the browser - Finder style
//

import SwiftUI

struct FileListView: View {
    @Bindable var viewModel: FileBrowserViewModel
    let onOpenEditor: (RemoteFile) -> Void
    let onGetInfo: (RemoteFile) -> Void

    var body: some View {
        Table(viewModel.sortedFiles, selection: $viewModel.selectedFiles, sortOrder: $sortOrder) {
            TableColumn("Name", sortUsing: nameSortComparator) { file in
                HStack(spacing: 6) {
                    Image(systemName: FileTypeService.iconName(for: file))
                        .foregroundStyle(FileTypeService.iconColor(for: file))
                        .frame(width: 16)

                    Text(file.name)
                        .lineLimit(1)
                }
                .onTapGesture(count: 2) {
                    handleDoubleClick(file)
                }
            }
            .width(min: 200)

            TableColumn("Kind", sortUsing: kindSortComparator) { file in
                Text(FileTypeService.typeDescription(for: file))
                    .foregroundStyle(.secondary)
            }
            .width(min: 100, ideal: 120)

            TableColumn("Date Modified", sortUsing: dateSortComparator) { file in
                Text(file.modificationDate?.fileListDisplayString ?? "--")
                    .foregroundStyle(.secondary)
            }
            .width(min: 120, ideal: 140)

            TableColumn("Size", sortUsing: sizeSortComparator) { file in
                Text(file.displaySize)
                    .foregroundStyle(.secondary)
            }
            .width(min: 60, ideal: 80)
        }
        .contextMenu(forSelectionType: UUID.self) { selectedIds in
            if let fileId = selectedIds.first,
               let file = viewModel.sortedFiles.first(where: { $0.id == fileId }) {
                fileContextMenu(for: file)
            }
        } primaryAction: { selectedIds in
            if let fileId = selectedIds.first,
               let file = viewModel.sortedFiles.first(where: { $0.id == fileId }) {
                handleDoubleClick(file)
            }
        }
        .onChange(of: sortOrder) { _, newOrder in
            updateSorting(newOrder)
        }
    }

    // MARK: - Sort State

    @State private var sortOrder: [KeyPathComparator<RemoteFile>] = [
        .init(\.name, order: .forward)
    ]

    private var nameSortComparator: KeyPathComparator<RemoteFile> {
        .init(\.name, order: .forward)
    }

    private var kindSortComparator: KeyPathComparator<RemoteFile> {
        .init(\.fileType.rawValue, order: .forward)
    }

    private var dateSortComparator: KeyPathComparator<RemoteFile> {
        .init(\.modificationDate, order: .forward)
    }

    private var sizeSortComparator: KeyPathComparator<RemoteFile> {
        .init(\.size, order: .forward)
    }

    private func updateSorting(_ order: [KeyPathComparator<RemoteFile>]) {
        guard let first = order.first else { return }

        let ascending = first.order == .forward

        if first.keyPath == \RemoteFile.name {
            viewModel.sortCriteria = .name
        } else if first.keyPath == \RemoteFile.fileType.rawValue {
            viewModel.sortCriteria = .type
        } else if first.keyPath == \RemoteFile.modificationDate {
            viewModel.sortCriteria = .date
        } else if first.keyPath == \RemoteFile.size {
            viewModel.sortCriteria = .size
        }

        viewModel.sortAscending = ascending
    }

    private func handleDoubleClick(_ file: RemoteFile) {
        Task {
            if file.isDirectory {
                await viewModel.navigateTo(file.path)
            } else if FileTypeService.isPreviewable(file) {
                onOpenEditor(file)
            }
        }
    }

    @ViewBuilder
    private func fileContextMenu(for file: RemoteFile) -> some View {
        if file.isFile {
            Button {
                onOpenEditor(file)
            } label: {
                Label("Open in Editor", systemImage: "pencil.and.outline")
            }

            Divider()
        }

        Button {
            viewModel.selectedFiles = [file.id]
            viewModel.copySelectedFiles()
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        Button {
            viewModel.selectedFiles = [file.id]
            viewModel.cutSelectedFiles()
        } label: {
            Label("Cut", systemImage: "scissors")
        }

        if viewModel.canPaste {
            Button {
                Task {
                    await viewModel.paste()
                }
            } label: {
                Label("Paste", systemImage: "doc.on.clipboard")
            }
        }

        Divider()

        Button {
            viewModel.startRename(file)
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Button {
            onGetInfo(file)
        } label: {
            Label("Get Info", systemImage: "info.circle")
        }

        Divider()

        if file.isFile {
            Button {
                Task {
                    await viewModel.downloadFile(file)
                }
            } label: {
                Label("Download", systemImage: "arrow.down.circle")
            }

            Divider()
        }

        Button(role: .destructive) {
            viewModel.confirmDelete([file])
        } label: {
            Label("Delete", systemImage: "trash")
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
