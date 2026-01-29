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

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: FileTypeService.iconName(for: file))
                .font(.system(size: 20))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(FileTypeService.iconColor(for: file))
                .frame(width: 24)

            // Name
            Text(file.name)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            // Size
            Text(file.displaySize)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)

            // Date
            Text(file.modificationDate?.fileListDisplayString ?? "—")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .trailing)

            // Permissions
            Text(file.permissions)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 90, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleClick()
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
