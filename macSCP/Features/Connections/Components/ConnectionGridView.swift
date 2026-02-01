//
//  ConnectionGridView.swift
//  macSCP
//
//  Grid view displaying connections - Modern macOS style
//

import SwiftUI

struct ConnectionGridView: View {
    @Bindable var viewModel: ConnectionListViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 16)
    ]

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView(message: "Loading connections...")

            case .success:
                if viewModel.filteredConnections.isEmpty {
                    emptyStateView
                } else {
                    connectionGrid
                }

            case .error(let error):
                ErrorView(error: error) {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if viewModel.searchText.isEmpty {
            switch viewModel.selectedSidebarItem {
            case .allConnections:
                EmptyStateView(
                    icon: "server.rack",
                    title: "No Connections",
                    message: "Add a new SSH connection to get started\nwith remote file management.",
                    actionTitle: "Add Connection"
                ) {
                    viewModel.isShowingNewConnectionSheet = true
                }
            case .folder:
                EmptyStateView(
                    icon: "folder",
                    title: "Empty Folder",
                    message: "This folder has no connections.\nDrag connections here or create a new one.",
                    actionTitle: "Add Connection"
                ) {
                    viewModel.isShowingNewConnectionSheet = true
                }
            }
        } else {
            EmptyStateView.noSearchResults
        }
    }

    private var connectionGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.filteredConnections) { connection in
                    ConnectionCardView(
                        connection: connection,
                        isSelected: viewModel.selectedConnections.contains(connection.id),
                        onConnect: {
                            viewModel.connectToServer(connection)
                        },
                        onEdit: {
                            viewModel.editConnection(connection)
                        },
                        onDuplicate: {
                            Task {
                                await viewModel.duplicateConnection(connection)
                            }
                        },
                        onDelete: {
                            Task {
                                await viewModel.deleteConnection(connection)
                            }
                        },
                        onSelect: { selected in
                            if selected {
                                viewModel.selectedConnections = [connection.id]
                            } else {
                                viewModel.selectedConnections.removeAll()
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }
            }
            .padding(20)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.filteredConnections.map(\.id))
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Preview
#Preview {
    ConnectionGridView(viewModel: DependencyContainer.shared.makeConnectionListViewModel())
}
