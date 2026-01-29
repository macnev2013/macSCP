//
//  FileRowView.swift
//  macSCP
//
//  Row view for a single file in the file list
//

import SwiftUI

struct FileRowView: View {
    let file: RemoteFile
    let isSelected: Bool
    let onDoubleClick: () -> Void

    var body: some View {
        HStack(spacing: UIConstants.smallSpacing) {
            // Icon
            FileIconView(file: file)
                .frame(width: 24, height: 24)

            // Name
            Text(file.name)
                .font(.body)
                .lineLimit(1)

            Spacer()

            // Size
            Text(file.displaySize)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)

            // Date
            if let date = file.modificationDate {
                Text(date.fileListDisplayString)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(width: 120, alignment: .trailing)
            } else {
                Text("--")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(width: 120, alignment: .trailing)
            }

            // Permissions
            Text(file.permissions)
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 4)
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
}
