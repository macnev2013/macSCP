//
//  BrowserToolbar.swift
//  macSCP
//
//  Toolbar for the file browser
//

import SwiftUI

struct BrowserToolbar: View {
    @Bindable var viewModel: FileBrowserViewModel

    var body: some View {
        HStack(spacing: UIConstants.spacing) {
            // Navigation buttons
            navigationButtons

            Divider()
                .frame(height: 20)

            // Action buttons
            actionButtons

            Spacer()

            // View options
            viewOptions
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.windowBackgroundColor))
    }

    private var navigationButtons: some View {
        HStack(spacing: 4) {
            Button {
                Task { await viewModel.goBack() }
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!viewModel.canGoBack)

            Button {
                Task { await viewModel.goForward() }
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!viewModel.canGoForward)

            Button {
                Task { await viewModel.goUp() }
            } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(!viewModel.canGoUp)

            Button {
                Task { await viewModel.goHome() }
            } label: {
                Image(systemName: "house")
            }

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
        .buttonStyle(.borderless)
    }

    private var actionButtons: some View {
        HStack(spacing: 4) {
            Menu {
                Button {
                    viewModel.isShowingNewFolderSheet = true
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }

                Button {
                    viewModel.isShowingNewFileSheet = true
                } label: {
                    Label("New File", systemImage: "doc.badge.plus")
                }
            } label: {
                Image(systemName: "plus")
            }

            Button {
                Task { await viewModel.uploadFiles() }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .help("Upload files")

            Divider()
                .frame(height: 16)

            Button {
                viewModel.copySelectedFiles()
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .disabled(viewModel.selectedFiles.isEmpty)
            .help("Copy")

            Button {
                viewModel.cutSelectedFiles()
            } label: {
                Image(systemName: "scissors")
            }
            .disabled(viewModel.selectedFiles.isEmpty)
            .help("Cut")

            Button {
                Task { await viewModel.paste() }
            } label: {
                Image(systemName: "doc.on.clipboard")
            }
            .disabled(!viewModel.canPaste)
            .help("Paste")

            Divider()
                .frame(height: 16)

            Button {
                viewModel.confirmDeleteSelected()
            } label: {
                Image(systemName: "trash")
            }
            .disabled(viewModel.selectedFiles.isEmpty)
            .help("Delete")
        }
        .buttonStyle(.borderless)
    }

    private var viewOptions: some View {
        HStack(spacing: 8) {
            Toggle(isOn: $viewModel.showHiddenFiles) {
                Image(systemName: "eye")
            }
            .toggleStyle(.button)
            .help("Show hidden files")

            Menu {
                ForEach(RemoteFile.SortCriteria.allCases, id: \.self) { criteria in
                    Button {
                        if viewModel.sortCriteria == criteria {
                            viewModel.sortAscending.toggle()
                        } else {
                            viewModel.sortCriteria = criteria
                            viewModel.sortAscending = true
                        }
                    } label: {
                        HStack {
                            Text(criteria.rawValue)
                            if viewModel.sortCriteria == criteria {
                                Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .menuStyle(.borderlessButton)
            .help("Sort options")
        }
    }
}

// MARK: - Preview
#Preview {
    BrowserToolbar(viewModel: DependencyContainer.shared.makeFileBrowserViewModel(
        connection: Connection(name: "Test", host: "localhost", username: "user"),
        sftpSession: SFTPSession(),
        password: "test"
    ))
}
