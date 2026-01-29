//
//  ConnectionGridView.swift
//  macSCP
//
//  Grid view displaying connections
//

import SwiftUI

struct ConnectionGridView: View {
    @Bindable var viewModel: ConnectionListViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: UIConstants.spacing)
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
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if viewModel.searchText.isEmpty {
            switch viewModel.selectedSidebarItem {
            case .allConnections:
                EmptyStateView(
                    icon: "server.rack",
                    title: "No Connections",
                    message: "Add a new SSH connection to get started.",
                    actionTitle: "Add Connection"
                ) {
                    viewModel.isShowingNewConnectionSheet = true
                }
            case .folder:
                EmptyStateView(
                    icon: "folder",
                    title: "Empty Folder",
                    message: "This folder has no connections. Drag connections here or create a new one.",
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
            LazyVGrid(columns: columns, spacing: UIConstants.spacing) {
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
                                viewModel.selectedConnections.insert(connection.id)
                            } else {
                                viewModel.selectedConnections.remove(connection.id)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview
#Preview {
    ConnectionGridView(viewModel: DependencyContainer.shared.makeConnectionListViewModel())
}
