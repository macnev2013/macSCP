//
//  BrowserToolbar.swift
//  macSCP
//
//  Toolbar for the file browser - Modern macOS style
//

import SwiftUI

struct BrowserToolbar: View {
    @Bindable var viewModel: FileBrowserViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Navigation buttons
            navigationButtons
                .padding(.horizontal, 12)

            Divider()
                .frame(height: 24)

            // Action buttons
            actionButtons
                .padding(.horizontal, 12)

            Spacer()

            // View options
            viewOptions
                .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .background(.ultraThinMaterial)
    }

    private var navigationButtons: some View {
        HStack(spacing: 2) {
            ToolbarButton(
                icon: "chevron.left",
                action: { Task { await viewModel.goBack() } },
                isDisabled: !viewModel.canGoBack,
                tooltip: "Go Back"
            )

            ToolbarButton(
                icon: "chevron.right",
                action: { Task { await viewModel.goForward() } },
                isDisabled: !viewModel.canGoForward,
                tooltip: "Go Forward"
            )

            ToolbarButton(
                icon: "chevron.up",
                action: { Task { await viewModel.goUp() } },
                isDisabled: !viewModel.canGoUp,
                tooltip: "Go Up"
            )

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)

            ToolbarButton(
                icon: "house",
                action: { Task { await viewModel.goHome() } },
                tooltip: "Go Home"
            )

            ToolbarButton(
                icon: "arrow.clockwise",
                action: { Task { await viewModel.refresh() } },
                tooltip: "Refresh"
            )
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 2) {
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
                ToolbarButtonLabel(icon: "plus", tooltip: "New")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 32)

            ToolbarButton(
                icon: "square.and.arrow.up",
                action: { Task { await viewModel.uploadFiles() } },
                tooltip: "Upload"
            )

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)

            ToolbarButton(
                icon: "doc.on.doc",
                action: { viewModel.copySelectedFiles() },
                isDisabled: viewModel.selectedFiles.isEmpty,
                tooltip: "Copy"
            )

            ToolbarButton(
                icon: "scissors",
                action: { viewModel.cutSelectedFiles() },
                isDisabled: viewModel.selectedFiles.isEmpty,
                tooltip: "Cut"
            )

            ToolbarButton(
                icon: "doc.on.clipboard",
                action: { Task { await viewModel.paste() } },
                isDisabled: !viewModel.canPaste,
                tooltip: "Paste"
            )

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)

            ToolbarButton(
                icon: "trash",
                action: { viewModel.confirmDeleteSelected() },
                isDisabled: viewModel.selectedFiles.isEmpty,
                tooltip: "Delete",
                isDestructive: true
            )
        }
    }

    private var viewOptions: some View {
        HStack(spacing: 2) {
            Toggle(isOn: $viewModel.showHiddenFiles) {
                Image(systemName: viewModel.showHiddenFiles ? "eye.fill" : "eye.slash")
                    .font(.system(size: 12, weight: .medium))
            }
            .toggleStyle(.button)
            .buttonStyle(.borderless)
            .frame(width: 32, height: 32)
            .help("Toggle hidden files")

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
                            Spacer()
                            if viewModel.sortCriteria == criteria {
                                Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                            }
                        }
                    }
                }
            } label: {
                ToolbarButtonLabel(icon: "arrow.up.arrow.down", tooltip: "Sort")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 32)
        }
    }
}

// MARK: - Toolbar Button
struct ToolbarButton: View {
    let icon: String
    let action: () -> Void
    var isDisabled: Bool = false
    var tooltip: String = ""
    var isDestructive: Bool = false

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(
                    isDisabled ? Color.secondary.opacity(0.5) :
                    (isDestructive && isHovering ? Color.red : Color.primary)
                )
                .frame(width: 28, height: 28)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            isPressed ? Color.primary.opacity(0.12) :
                            (isHovering ? Color.primary.opacity(0.06) : .clear)
                        )
                }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .onHover { hovering in
            isHovering = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeInOut(duration: 0.1), value: isHovering)
        .animation(.easeInOut(duration: 0.05), value: isPressed)
        .help(tooltip)
    }
}

// MARK: - Toolbar Button Label (for menus)
struct ToolbarButtonLabel: View {
    let icon: String
    var tooltip: String = ""

    @State private var isHovering = false

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.primary)
            .frame(width: 28, height: 28)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovering ? Color.primary.opacity(0.06) : .clear)
            }
            .onHover { hovering in
                isHovering = hovering
            }
            .animation(.easeInOut(duration: 0.1), value: isHovering)
            .help(tooltip)
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
