//
//  FileRowView.swift
//  macSCP
//
//  Row view for a single file in the file list - Modern macOS style
//

import SwiftUI

struct FileRowView: View {
    let file: RemoteFile
    let isSelected: Bool
    let onDoubleClick: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: iconGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: FileTypeService.iconName(for: file))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if file.isDirectory {
                    Text("Folder")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Size
            Text(file.displaySize)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)

            // Date
            if let date = file.modificationDate {
                Text(date.fileListDisplayString)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .trailing)
            } else {
                Text("—")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .frame(width: 100, alignment: .trailing)
            }

            // Permissions
            Text(file.permissions)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .frame(width: 90, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovering && !isSelected ? Color.primary.opacity(0.04) : .clear)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture(count: 2) {
            onDoubleClick()
        }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }

    private var iconGradientColors: [Color] {
        if file.isDirectory {
            return [.cyan.opacity(0.8), .blue.opacity(0.7)]
        }

        switch file.fileType {
        case .image:
            return [.purple.opacity(0.8), .pink.opacity(0.7)]
        case .video:
            return [.red.opacity(0.8), .orange.opacity(0.7)]
        case .audio:
            return [.pink.opacity(0.8), .red.opacity(0.7)]
        case .document, .text, .pdf:
            return [.blue.opacity(0.8), .indigo.opacity(0.7)]
        case .code, .configuration:
            return [.green.opacity(0.8), .teal.opacity(0.7)]
        case .archive:
            return [.brown.opacity(0.8), .orange.opacity(0.7)]
        case .spreadsheet:
            return [.green.opacity(0.8), .cyan.opacity(0.7)]
        case .presentation:
            return [.orange.opacity(0.8), .red.opacity(0.7)]
        case .executable:
            return [.gray.opacity(0.7), .gray.opacity(0.5)]
        default:
            return [.gray.opacity(0.6), .gray.opacity(0.4)]
        }
    }
}

// MARK: - File Icon View
struct FileIconView: View {
    let file: RemoteFile

    var body: some View {
        Image(systemName: FileTypeService.iconName(for: file))
            .font(.title3)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(FileTypeService.iconColor(for: file))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 0) {
        FileRowView(
            file: RemoteFile(
                name: "Documents",
                path: "/home/user/Documents",
                isDirectory: true,
                size: 0,
                permissions: "drwxr-xr-x",
                modificationDate: Date()
            ),
            isSelected: false,
            onDoubleClick: {}
        )

        Divider()
            .padding(.leading, 48)

        FileRowView(
            file: RemoteFile(
                name: "config.json",
                path: "/home/user/config.json",
                isDirectory: false,
                size: 1024,
                permissions: "-rw-r--r--",
                modificationDate: Date()
            ),
            isSelected: true,
            onDoubleClick: {}
        )

        Divider()
            .padding(.leading, 48)

        FileRowView(
            file: RemoteFile(
                name: "photo.jpg",
                path: "/home/user/photo.jpg",
                isDirectory: false,
                size: 2048576,
                permissions: "-rw-r--r--",
                modificationDate: nil
            ),
            isSelected: false,
            onDoubleClick: {}
        )
    }
    .padding()
    .background(Color(.windowBackgroundColor))
}
