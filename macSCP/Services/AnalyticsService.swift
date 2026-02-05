//
//  AnalyticsService.swift
//  macSCP
//
//  Privacy-focused analytics using TelemetryDeck
//

import Foundation
import TelemetryClient

enum AnalyticsService {
    // MARK: - Storage Keys

    private enum StorageKey {
        static let anonymousUserId = "com.macSCP.anonymousUserId"
        static let sessionCount = "com.macSCP.sessionCount"
        static let firstLaunchDate = "com.macSCP.firstLaunchDate"
        static let totalConnectionsCreated = "com.macSCP.totalConnectionsCreated"
        static let totalFilesTransferred = "com.macSCP.totalFilesTransferred"
    }

    // MARK: - Anonymous User ID

    /// Returns a stable anonymous user ID, creating one if it doesn't exist.
    /// This ID is persistent, unique per installation, and not personally identifiable.
    static var anonymousUserId: String {
        if let existingId = UserDefaults.standard.string(forKey: StorageKey.anonymousUserId) {
            return existingId
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: StorageKey.anonymousUserId)
        return newId
    }

    // MARK: - Session Tracking

    private(set) static var sessionCount: Int {
        get { UserDefaults.standard.integer(forKey: StorageKey.sessionCount) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.sessionCount) }
    }

    private static var firstLaunchDate: Date {
        if let date = UserDefaults.standard.object(forKey: StorageKey.firstLaunchDate) as? Date {
            return date
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: StorageKey.firstLaunchDate)
        return now
    }

    /// Days since first app launch
    private static var daysSinceFirstLaunch: Int {
        Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
    }

    // MARK: - Cumulative Stats

    private(set) static var totalConnectionsCreated: Int {
        get { UserDefaults.standard.integer(forKey: StorageKey.totalConnectionsCreated) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.totalConnectionsCreated) }
    }

    private(set) static var totalFilesTransferred: Int {
        get { UserDefaults.standard.integer(forKey: StorageKey.totalFilesTransferred) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.totalFilesTransferred) }
    }

    // MARK: - Configuration

    static func initialize() {
        let config = TelemetryManagerConfiguration(appID: "B5BEE195-393B-4B84-8B10-0BEC90496251")
        config.defaultUser = anonymousUserId
        TelemetryManager.initialize(with: config)

        // Increment session count
        sessionCount += 1

        // Track app launch with context
        track(.appLaunched, with: [
            "session_number": "\(sessionCount)",
            "days_since_install": "\(daysSinceFirstLaunch)",
            "is_first_launch": sessionCount == 1 ? "true" : "false"
        ])
    }

    // MARK: - Core Tracking

    static func track(_ event: Event) {
        TelemetryManager.send(event.rawValue)
    }

    static func track(_ event: Event, with parameters: [String: String]) {
        TelemetryManager.send(event.rawValue, with: parameters)
    }

    // MARK: - Connection Tracking

    static func trackConnectionCreated(protocol: ConnectionProtocol) {
        totalConnectionsCreated += 1
        track(.connectionCreated, with: [
            "protocol": `protocol`.rawValue,
            "total_connections_created": "\(totalConnectionsCreated)"
        ])
    }

    static func trackConnectionConnected(protocol: ConnectionProtocol, success: Bool) {
        track(.connectionConnected, with: [
            "protocol": `protocol`.rawValue,
            "success": success ? "true" : "false"
        ])
    }

    static func trackConnectionFailed(protocol: ConnectionProtocol, errorType: String) {
        track(.connectionFailed, with: [
            "protocol": `protocol`.rawValue,
            "error_type": errorType
        ])
    }

    // MARK: - File Transfer Tracking

    static func trackFileUploaded(protocol: ConnectionProtocol, fileCount: Int, totalBytes: Int64) {
        totalFilesTransferred += fileCount
        track(.fileUploaded, with: [
            "protocol": `protocol`.rawValue,
            "file_count": "\(fileCount)",
            "size_category": sizeCategory(for: totalBytes),
            "total_files_transferred": "\(totalFilesTransferred)"
        ])
    }

    static func trackFileDownloaded(protocol: ConnectionProtocol, fileCount: Int, totalBytes: Int64) {
        totalFilesTransferred += fileCount
        track(.fileDownloaded, with: [
            "protocol": `protocol`.rawValue,
            "file_count": "\(fileCount)",
            "size_category": sizeCategory(for: totalBytes),
            "total_files_transferred": "\(totalFilesTransferred)"
        ])
    }

    static func trackTransferFailed(protocol: ConnectionProtocol, operation: String, errorType: String) {
        track(.transferFailed, with: [
            "protocol": `protocol`.rawValue,
            "operation": operation,
            "error_type": errorType
        ])
    }

    // MARK: - File Operations Tracking

    static func trackFileOperation(_ operation: FileOperation, protocol: ConnectionProtocol, count: Int = 1) {
        let event: Event
        switch operation {
        case .delete: event = .fileDeleted
        case .rename: event = .fileRenamed
        case .createFolder: event = .folderCreatedRemote
        }

        track(event, with: [
            "protocol": `protocol`.rawValue,
            "count": "\(count)"
        ])
    }

    // MARK: - Feature Usage Tracking

    static func trackFileBrowserOpened(protocol: ConnectionProtocol) {
        track(.fileBrowserOpened, with: [
            "protocol": `protocol`.rawValue
        ])
    }

    static func trackEditorOpened(fileExtension: String) {
        track(.editorOpened, with: [
            "file_type": fileExtension.isEmpty ? "unknown" : fileExtension.lowercased()
        ])
    }

    static func trackFileSaved(fileExtension: String) {
        track(.fileSaved, with: [
            "file_type": fileExtension.isEmpty ? "unknown" : fileExtension.lowercased()
        ])
    }

    // MARK: - Helpers

    private static func sizeCategory(for bytes: Int64) -> String {
        switch bytes {
        case 0..<1024:
            return "tiny_under_1kb"
        case 1024..<(1024 * 1024):
            return "small_1kb_1mb"
        case (1024 * 1024)..<(10 * 1024 * 1024):
            return "medium_1mb_10mb"
        case (10 * 1024 * 1024)..<(100 * 1024 * 1024):
            return "large_10mb_100mb"
        case (100 * 1024 * 1024)..<(1024 * 1024 * 1024):
            return "xlarge_100mb_1gb"
        default:
            return "huge_over_1gb"
        }
    }

    // MARK: - Events

    enum Event: String {
        // App lifecycle
        case appLaunched = "app_launched"

        // Connections
        case connectionCreated = "connection_created"
        case connectionEdited = "connection_edited"
        case connectionDeleted = "connection_deleted"
        case connectionConnected = "connection_connected"
        case connectionFailed = "connection_failed"

        // Folders (local organization)
        case folderCreated = "folder_created"
        case folderDeleted = "folder_deleted"

        // File browser
        case fileBrowserOpened = "file_browser_opened"
        case fileUploaded = "file_uploaded"
        case fileDownloaded = "file_downloaded"
        case fileDeleted = "file_deleted"
        case fileRenamed = "file_renamed"
        case folderCreatedRemote = "folder_created_remote"
        case transferFailed = "transfer_failed"

        // Editor
        case editorOpened = "editor_opened"
        case fileSaved = "file_saved"

        // File info
        case fileInfoOpened = "file_info_opened"
    }

    enum ConnectionProtocol: String {
        case sftp = "sftp"
        case s3 = "s3"

        init(from connectionType: ConnectionType) {
            switch connectionType {
            case .sftp: self = .sftp
            case .s3: self = .s3
            }
        }
    }

    enum FileOperation {
        case delete
        case rename
        case createFolder
    }
}
