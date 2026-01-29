//
//  FileInfoViewModel.swift
//  macSCP
//
//  ViewModel for the file info feature
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class FileInfoViewModel {
    let file: RemoteFile
    let connectionName: String

    init(file: RemoteFile, connectionName: String) {
        self.file = file
        self.connectionName = connectionName
    }

    // MARK: - Computed Properties

    var fileName: String {
        file.name
    }

    var filePath: String {
        file.path
    }

    var fileSize: String {
        file.displaySize
    }

    var fileType: String {
        FileTypeService.typeDescription(for: file)
    }

    var permissions: String {
        file.permissions
    }

    var permissionsDescription: String {
        FileTypeService.formatPermissions(file.permissions)
    }

    var modificationDate: String {
        file.modificationDate?.fileInfoDisplayString ?? "Unknown"
    }

    var iconName: String {
        FileTypeService.iconName(for: file)
    }

    var iconColor: Color {
        FileTypeService.iconColor(for: file)
    }

    var isDirectory: Bool {
        file.isDirectory
    }

    var isHidden: Bool {
        file.isHidden
    }

    var isSymlink: Bool {
        file.isSymlink
    }

    var isExecutable: Bool {
        file.isExecutable
    }

    var isEditable: Bool {
        file.fileType.isEditable
    }

    var parentDirectory: String {
        file.parentPath
    }

    var fileExtension: String {
        file.fileExtension.isEmpty ? "None" : file.fileExtension.uppercased()
    }
}
