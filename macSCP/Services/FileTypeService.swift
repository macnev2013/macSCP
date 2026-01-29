//
//  FileTypeService.swift
//  macSCP
//
//  Service for file type detection and categorization
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum FileTypeService {
    /// Returns the SF Symbol name for a file
    static func iconName(for file: RemoteFile) -> String {
        if file.isDirectory {
            return "folder.fill"
        }

        return file.fileType.iconName
    }

    /// Returns the icon color for a file type
    static func iconColor(for file: RemoteFile) -> Color {
        if file.isDirectory {
            return .blue
        }

        switch file.fileType {
        case .code, .configuration:
            return .orange
        case .image:
            return .purple
        case .video:
            return .pink
        case .audio:
            return .green
        case .archive:
            return .brown
        case .document, .text:
            return .blue
        case .spreadsheet:
            return .green
        case .presentation:
            return .orange
        case .pdf:
            return .red
        case .executable:
            return .gray
        default:
            return .secondary
        }
    }

    /// Returns whether a file can be previewed/edited in the app
    static func isPreviewable(_ file: RemoteFile) -> Bool {
        guard file.isFile else { return false }
        guard file.size <= FileOperationConstants.maxFilePreviewSize else { return false }

        return file.fileType.isEditable
    }

    /// Returns the UTType for a file extension
    static func utType(for extension: String) -> UTType? {
        UTType(filenameExtension: `extension`)
    }

    /// Returns the MIME type for a file
    static func mimeType(for file: RemoteFile) -> String {
        guard let utType = utType(for: file.fileExtension) else {
            return "application/octet-stream"
        }
        return utType.preferredMIMEType ?? "application/octet-stream"
    }

    /// Returns a human-readable description of the file type
    static func typeDescription(for file: RemoteFile) -> String {
        if file.isDirectory {
            return "Folder"
        }

        if file.isSymlink {
            return "Symbolic Link"
        }

        switch file.fileType {
        case .directory:
            return "Folder"
        case .text:
            return "Text Document"
        case .code:
            return "\(file.fileExtension.uppercased()) Source File"
        case .image:
            return "\(file.fileExtension.uppercased()) Image"
        case .video:
            return "\(file.fileExtension.uppercased()) Video"
        case .audio:
            return "\(file.fileExtension.uppercased()) Audio"
        case .archive:
            return "\(file.fileExtension.uppercased()) Archive"
        case .document:
            return "\(file.fileExtension.uppercased()) Document"
        case .spreadsheet:
            return "Spreadsheet"
        case .presentation:
            return "Presentation"
        case .pdf:
            return "PDF Document"
        case .executable:
            return "Executable"
        case .configuration:
            return "Configuration File"
        case .unknown:
            if file.fileExtension.isEmpty {
                return "Document"
            }
            return "\(file.fileExtension.uppercased()) File"
        }
    }

    /// Groups files by their type
    static func groupByType(_ files: [RemoteFile]) -> [FileType: [RemoteFile]] {
        Dictionary(grouping: files, by: { $0.fileType })
    }

    /// Returns files filtered by type
    static func filter(_ files: [RemoteFile], byType type: FileType) -> [RemoteFile] {
        files.filter { $0.fileType == type }
    }
}

// MARK: - File Size Formatting
extension FileTypeService {
    /// Formats a byte count as a human-readable string
    static func formatSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// Formats permissions as a human-readable string
    static func formatPermissions(_ permissions: String) -> String {
        guard permissions.count == 10 else { return permissions }

        let type: String
        switch permissions.first {
        case "d": type = "Directory"
        case "l": type = "Symbolic Link"
        case "-": type = "File"
        case "b": type = "Block Device"
        case "c": type = "Character Device"
        case "p": type = "Named Pipe"
        case "s": type = "Socket"
        default: type = "Unknown"
        }

        let permString = String(permissions.dropFirst())
        let owner = formatPermissionGroup(String(permString.prefix(3)))
        let group = formatPermissionGroup(String(permString.dropFirst(3).prefix(3)))
        let other = formatPermissionGroup(String(permString.suffix(3)))

        return "\(type) - Owner: \(owner), Group: \(group), Others: \(other)"
    }

    private static func formatPermissionGroup(_ perms: String) -> String {
        var result: [String] = []
        if perms.contains("r") { result.append("Read") }
        if perms.contains("w") { result.append("Write") }
        if perms.contains("x") { result.append("Execute") }
        return result.isEmpty ? "None" : result.joined(separator: ", ")
    }
}
