//
//  EmptyStateView.swift
//  macSCP
//
//  Reusable empty state view
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: UIConstants.spacing) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    action()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(UIConstants.spacing * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Empty States
extension EmptyStateView {
    static var noConnections: EmptyStateView {
        EmptyStateView(
            icon: "server.rack",
            title: "No Connections",
            message: "Add a new SSH connection to get started."
        )
    }

    static var noFiles: EmptyStateView {
        EmptyStateView(
            icon: "folder",
            title: "Empty Directory",
            message: "This directory contains no files."
        )
    }

    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No items match your search criteria."
        )
    }

    static var noFolderSelected: EmptyStateView {
        EmptyStateView(
            icon: "folder.badge.questionmark",
            title: "No Folder Selected",
            message: "Select a folder from the sidebar to view its connections."
        )
    }
}

// MARK: - Preview
#Preview("Empty State") {
    EmptyStateView(
        icon: "folder.badge.plus",
        title: "No Files",
        message: "This folder is empty. Add some files to get started.",
        actionTitle: "Upload File",
        action: {}
    )
    .frame(width: 400, height: 300)
}

#Preview("No Connections") {
    EmptyStateView.noConnections
        .frame(width: 400, height: 300)
}
