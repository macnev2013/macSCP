//
//  ConnectionCardView.swift
//  macSCP
//
//  Card view for displaying a single connection - Modern macOS style
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
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and auth indicator
            HStack(spacing: 12) {
                // Server icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .blue.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: connection.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(connection.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(connection.connectionString)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            // Description
            if let description = connection.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)

            // Tags and status
            HStack(spacing: 6) {
                if !connection.tags.isEmpty {
                    ForEach(connection.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.quaternary, in: Capsule())
                    }
                    if connection.tags.count > 2 {
                        Text("+\(connection.tags.count - 2)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                // Connect button on hover
                if isHovering {
                    Button {
                        onConnect()
                    } label: {
                        Text("Connect")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
        .padding(14)
        .frame(height: 140)
        .background {
            ZStack {
                // Base material background
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Selection/hover highlight
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : (isHovering ? Color.primary.opacity(0.03) : .clear))

                // Border
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor.opacity(0.5) : Color.primary.opacity(isHovering ? 0.1 : 0.06),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .shadow(
            color: .black.opacity(isHovering ? 0.12 : 0.06),
            radius: isHovering ? 8 : 4,
            x: 0,
            y: isHovering ? 4 : 2
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture(count: 2) {
            onConnect()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    onSelect(!isSelected)
                }
        )
        .contextMenu {
            Button {
                onConnect()
            } label: {
                Label("Connect", systemImage: "cable.connector")
            }

            Divider()

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 16) {
        ConnectionCardView(
            connection: Connection(
                name: "Production Server",
                host: "prod.example.com",
                username: "admin",
                description: "Main production server for deployment",
                tags: ["production", "critical", "aws"]
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
    .padding(24)
    .frame(width: 520)
    .background(Color(.windowBackgroundColor))
}
