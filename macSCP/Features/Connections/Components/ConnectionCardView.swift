//
//  ConnectionCardView.swift
//  macSCP
//
//  Card view for displaying a single connection
//

import SwiftUI

struct ConnectionCardView: View {
    let connection: Connection
    let isSelected: Bool
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onSelect: (Bool) -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
            // Header
            HStack {
                Image(systemName: connection.iconName)
                    .font(.title2)
                    .foregroundStyle(.blue)

                Spacer()

                if connection.authMethod == .privateKey {
                    Image(systemName: "key.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Name
            Text(connection.name)
                .font(.headline)
                .lineLimit(1)

            // Connection string
            Text(connection.connectionString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Description
            if let description = connection.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }

            Spacer()

            // Tags
            if !connection.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(connection.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2), in: Capsule())
                    }
                    if connection.tags.count > 3 {
                        Text("+\(connection.tags.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture(count: 2) {
            onConnect()
        }
        .onTapGesture(count: 1) {
            onSelect(!isSelected)
        }
        .contextMenu {
            Button("Connect") {
                onConnect()
            }

            Divider()

            Button("Edit") {
                onEdit()
            }

            Button("Duplicate") {
                onDuplicate()
            }

            Divider()

            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HStack {
        ConnectionCardView(
            connection: Connection(
                name: "Production Server",
                host: "prod.example.com",
                username: "admin",
                description: "Main production server",
                tags: ["production", "critical"]
            ),
            isSelected: false,
            onConnect: {},
            onEdit: {},
            onDuplicate: {},
            onDelete: {},
            onSelect: { _ in }
        )

        ConnectionCardView(
            connection: Connection(
                name: "Dev Server",
                host: "dev.example.com",
                username: "developer",
                authMethod: .privateKey,
                privateKeyPath: "~/.ssh/id_rsa"
            ),
            isSelected: true,
            onConnect: {},
            onEdit: {},
            onDuplicate: {},
            onDelete: {},
            onSelect: { _ in }
        )
    }
    .padding()
    .frame(width: 500)
}
