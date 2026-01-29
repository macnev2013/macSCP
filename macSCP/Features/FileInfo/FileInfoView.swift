//
//  FileInfoView.swift
//  macSCP
//
//  View displaying file information
//

import SwiftUI

struct FileInfoView: View {
    let viewModel: FileInfoViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header with icon
            headerSection

            Divider()

            // Info sections
            ScrollView {
                VStack(alignment: .leading, spacing: UIConstants.spacing) {
                    generalSection
                    locationSection
                    permissionsSection

                    if viewModel.isDirectory {
                        directorySection
                    } else {
                        fileSection
                    }
                }
                .padding()
            }
        }
        .frame(width: WindowSize.fileInfo.width, height: WindowSize.fileInfo.height)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: UIConstants.smallSpacing) {
            Image(systemName: viewModel.iconName)
                .font(.system(size: 48))
                .foregroundStyle(viewModel.iconColor)

            Text(viewModel.fileName)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(viewModel.fileType)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.controlBackgroundColor))
    }

    private var generalSection: some View {
        InfoSection(title: "General") {
            InfoRow(label: "Kind", value: viewModel.fileType)
            InfoRow(label: "Size", value: viewModel.fileSize)

            if !viewModel.isDirectory {
                InfoRow(label: "Extension", value: viewModel.fileExtension)
            }

            InfoRow(label: "Modified", value: viewModel.modificationDate)
        }
    }

    private var locationSection: some View {
        InfoSection(title: "Location") {
            InfoRow(label: "Path", value: viewModel.filePath)
            InfoRow(label: "Parent", value: viewModel.parentDirectory)
            InfoRow(label: "Server", value: viewModel.connectionName)
        }
    }

    private var permissionsSection: some View {
        InfoSection(title: "Permissions") {
            InfoRow(label: "Mode", value: viewModel.permissions)

            VStack(alignment: .leading, spacing: 4) {
                Text("Details")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.permissionsDescription)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
    }

    private var directorySection: some View {
        InfoSection(title: "Directory Info") {
            InfoRow(label: "Type", value: "Folder")
        }
    }

    private var fileSection: some View {
        InfoSection(title: "File Info") {
            InfoRow(label: "Hidden", value: viewModel.isHidden ? "Yes" : "No")
            InfoRow(label: "Executable", value: viewModel.isExecutable ? "Yes" : "No")
            InfoRow(label: "Editable", value: viewModel.isEditable ? "Yes" : "No")

            if viewModel.isSymlink {
                InfoRow(label: "Symlink", value: "Yes")
            }
        }
    }
}

// MARK: - Info Section
private struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: UIConstants.smallCornerRadius))
        }
    }
}

// MARK: - Info Row
private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(value)
                .font(.callout)
                .textSelection(.enabled)
                .lineLimit(3)
                .truncationMode(.middle)
        }
    }
}

// MARK: - Preview
#Preview {
    FileInfoView(viewModel: FileInfoViewModel(
        file: RemoteFile(
            name: "example.swift",
            path: "/home/user/projects/example.swift",
            isDirectory: false,
            size: 4096,
            permissions: "-rw-r--r--",
            modificationDate: Date()
        ),
        connectionName: "Production Server"
    ))
}
