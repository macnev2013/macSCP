//
//  ConnectionCardView.swift
//  macSCP
//
//  Card view for displaying a single connection - macOS Tahoe style
//

import SwiftUI

struct ConnectionCardView: View {
    let connection: Connection
    let isSelected: Bool
    let onConnect: () -> Void
    let onOpenTerminal: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onSelect: (Bool) -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            HStack(spacing: 12) {
                // Server icon with glass effect
                ZStack {
                    // Glass circle
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 42, height: 42)

                    // Subtle gradient overlay
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.2),
                                    Color.cyan.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)

                    // Inner highlight
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                        .frame(width: 42, height: 42)

                    Image(systemName: connection.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 3) {
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

            // Tags and connect button
            HStack(spacing: 6) {
                if !connection.tags.isEmpty {
                    ForEach(connection.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    if connection.tags.count > 2 {
                        Text("+\(connection.tags.count - 2)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                // Action buttons on hover
                HStack(spacing: 8) {
                    // File browser button
                    Button(action: onConnect) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.primary.opacity(0.8))
                            .frame(width: 30, height: 30)
                            .background(.primary.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Open File Browser")

                    // Terminal button (SFTP only)
                    if connection.connectionType == .sftp {
                        Button(action: onOpenTerminal) {
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary.opacity(0.8))
                                .frame(width: 30, height: 30)
                                .background(.primary.opacity(0.1), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Open Terminal")
                    }
                }
                .opacity(isHovering ? 1 : 0)
            }
        }
        .padding(16)
        .frame(height: 140)
        .background {
            ZStack {
                // Base glass background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Gradient overlay for depth
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovering ? 0.08 : 0.04),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Selection highlight
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.accentColor.opacity(0.1))
                }

                // Border with gradient
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected
                                ? [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.3)]
                                : [Color.white.opacity(isHovering ? 0.3 : 0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
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
                Label("Open File Browser", systemImage: "folder")
            }

            Button {
                onOpenTerminal()
            } label: {
                Label("Open Terminal", systemImage: "terminal")
            }
            .disabled(connection.connectionType != .sftp)

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
            onOpenTerminal: {},
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
            onOpenTerminal: {},
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
