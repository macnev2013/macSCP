//
//  Constants.swift
//  macSCP
//
//  App-wide constants and configuration values
//

import Foundation
import SwiftUI

// MARK: - App Constants
enum AppConstants {
    static let bundleIdentifier = "com.macSCP"
    static let keychainService = "com.macSCP.ssh"
    static let keychainS3Service = "com.macSCP.s3"
    static let defaultSSHPort = 22
    static let maxRecentConnections = 10
}

// MARK: - Window Identifiers
enum WindowID {
    static let main = "main"
    static let fileBrowser = "file-browser"
    static let fileEditor = "file-editor"
    static let fileInfo = "file-info"
    static let terminal = "terminal"
}

// MARK: - Window Sizes
enum WindowSize {
    static let main = CGSize(width: 900, height: 600)
    static let fileBrowser = CGSize(width: 1000, height: 700)
    static let fileEditor = CGSize(width: 800, height: 600)
    static let fileInfo = CGSize(width: 300, height: 400)
    static let terminal = CGSize(width: 900, height: 600)
    static let minMain = CGSize(width: 700, height: 450)
    static let minFileBrowser = CGSize(width: 600, height: 400)
    static let minTerminal = CGSize(width: 600, height: 400)
}

// MARK: - UI Constants
enum UIConstants {
    static let cornerRadius: CGFloat = 8
    static let smallCornerRadius: CGFloat = 4
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let iconSize: CGFloat = 24
    static let smallIconSize: CGFloat = 16
    static let animationDuration: TimeInterval = 0.25
    static let debounceInterval: TimeInterval = 0.3
}

// MARK: - File Operations
enum FileOperationConstants {
    static let chunkSize = 1024 * 1024 // 1MB chunks for file transfer
    static let maxFilePreviewSize: Int64 = 10 * 1024 * 1024 // 10MB max for preview
    static let defaultPermissions: UInt16 = 0o644
    static let directoryPermissions: UInt16 = 0o755
}
