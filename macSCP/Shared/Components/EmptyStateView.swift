//
//  EmptyStateView.swift
//  macSCP
//
//  Reusable empty state view - Modern macOS style
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
        VStack(spacing: 20) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.15), .cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            if let actionTitle = actionTitle, let action = action {
                Button {
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Empty States
extension EmptyStateView {
    static var noConnections: EmptyStateView {
        EmptyStateView(
            icon: "server.rack",
            title: "No Connections",
            message: "Add a new SSH connection to get started with\nremote file management."
        )
    }

    static var noFiles: EmptyStateView {
        EmptyStateView(
            icon: "folder",
            title: "Empty Directory",
            message: "This directory is empty.\nUpload files or create new folders."
        )
    }

    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try adjusting your search terms\nor filters to find what you're looking for."
        )
    }

    static var noFolderSelected: EmptyStateView {
        EmptyStateView(
            icon: "folder.badge.questionmark",
            title: "No Folder Selected",
            message: "Select a folder from the sidebar\nto view its connections."
        )
    }
}

// MARK: - Preview
#Preview("Empty State") {
    EmptyStateView(
        icon: "folder.badge.plus",
        title: "No Files",
        message: "This folder is empty.\nAdd some files to get started.",
        actionTitle: "Upload Files",
        action: {}
    )
    .frame(width: 400, height: 350)
    .background(Color(.windowBackgroundColor))
}

#Preview("No Connections") {
    EmptyStateView.noConnections
        .frame(width: 400, height: 350)
        .background(Color(.windowBackgroundColor))
}
