//
//  ConnectionListViewModel.swift
//  macSCP
//
//  ViewModel for the connection list feature
//

import Foundation
import SwiftUI

enum SidebarSelection: Hashable, Sendable {
    case allConnections
    case folder(UUID)
}

@MainActor
@Observable
final class ConnectionListViewModel {
    // MARK: - Published State
    private(set) var connections: [Connection] = []
    private(set) var folders: [Folder] = []
    private(set) var state: ViewState<Void> = .idle
    var error: AppError?

    var selectedSidebarItem: SidebarSelection = .allConnections
    var searchText: String = ""
    var selectedConnectionId: UUID?

    // Sheet states
    var isShowingNewConnectionSheet = false
    var isShowingEditConnectionSheet = false
    var isShowingNewFolderSheet = false
    var isShowingPasswordPrompt = false
    var isShowingDeleteFolderAlert = false

    // Editing state
    var connectionToEdit: Connection?
    var connectionToConnect: Connection?
    var folderToDelete: Folder?

    // Window opening state
    var pendingWindowId: String?
    var pendingTerminalWindowId: String?

    // MARK: - Dependencies
    private let connectionRepository: ConnectionRepositoryProtocol
    private let folderRepository: FolderRepositoryProtocol
    private let keychainService: KeychainServiceProtocol
    private let windowManager: WindowManager

    // MARK: - Initialization
    init(
        connectionRepository: ConnectionRepositoryProtocol,
        folderRepository: FolderRepositoryProtocol,
        keychainService: KeychainServiceProtocol,
        windowManager: WindowManager
    ) {
        self.connectionRepository = connectionRepository
        self.folderRepository = folderRepository
        self.keychainService = keychainService
        self.windowManager = windowManager
    }

    // MARK: - Computed Properties

    var filteredConnections: [Connection] {
        var result: [Connection]

        switch selectedSidebarItem {
        case .allConnections:
            result = connections
        case .folder(let folderId):
            result = connections.filter { $0.folderId == folderId }
        }

        if !searchText.isEmpty {
            result = result.filter { connection in
                connection.name.localizedCaseInsensitiveContains(searchText) ||
                connection.host.localizedCaseInsensitiveContains(searchText) ||
                connection.username.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var unfolderedConnections: [Connection] {
        connections.filter { $0.folderId == nil }
    }

    var totalConnectionCount: Int {
        connections.count
    }

    func connectionCount(for folderId: UUID) -> Int {
        connections.filter { $0.folderId == folderId }.count
    }

    var selectedConnection: Connection? {
        guard let id = selectedConnectionId else { return nil }
        return connections.first { $0.id == id }
    }

    var selectedFolder: Folder? {
        guard case .folder(let id) = selectedSidebarItem else { return nil }
        return folders.first { $0.id == id }
    }

    // MARK: - Data Loading

    func loadData() async {
        state = .loading

        do {
            async let connectionsTask = connectionRepository.fetchAll()
            async let foldersTask = folderRepository.fetchAll()

            connections = try await connectionsTask
            folders = try await foldersTask
            state = .success(())
        } catch {
            logError("Failed to load data: \(error)", category: .database)
            state = .error(AppError.from(error))
        }
    }

    func refresh() async {
        await loadData()
    }

    // MARK: - Connection Actions

    func saveConnection(_ connection: Connection, password: String?) async {
        do {
            try await connectionRepository.save(connection)

            if connection.savePassword, let password = password, !password.isEmpty {
                if connection.connectionType == .s3 {
                    // For S3, store credentials (username is access key, password is secret)
                    let credentials = S3Credentials(
                        accessKeyId: connection.username,
                        secretAccessKey: password
                    )
                    try keychainService.saveS3Credentials(credentials, for: connection.id)
                } else {
                    try keychainService.savePassword(password, for: connection.id)
                }
            }

            await loadData()
            isShowingNewConnectionSheet = false
            AnalyticsService.trackConnectionCreated(protocol: .init(from: connection.connectionType))
            logInfo("Connection saved: \(connection.name)", category: .database)
        } catch {
            logError("Failed to save connection: \(error)", category: .database)
            self.error = AppError.from(error)
        }
    }

    func updateConnection(_ connection: Connection, password: String?) async {
        do {
            try await connectionRepository.update(connection)

            if connection.savePassword, let password = password, !password.isEmpty {
                if connection.connectionType == .s3 {
                    let credentials = S3Credentials(
                        accessKeyId: connection.username,
                        secretAccessKey: password
                    )
                    try keychainService.updateS3Credentials(credentials, for: connection.id)
                } else {
                    try keychainService.updatePassword(password, for: connection.id)
                }
            } else if !connection.savePassword {
                if connection.connectionType == .s3 {
                    try? keychainService.deleteS3Credentials(for: connection.id)
                } else {
                    try? keychainService.deletePassword(for: connection.id)
                }
            }

            await loadData()
            isShowingEditConnectionSheet = false
            connectionToEdit = nil
            AnalyticsService.track(.connectionEdited, with: [
                "protocol": AnalyticsService.ConnectionProtocol(from: connection.connectionType).rawValue
            ])
            logInfo("Connection updated: \(connection.name)", category: .database)
        } catch {
            logError("Failed to update connection: \(error)", category: .database)
            self.error = AppError.from(error)
        }
    }

    func deleteConnection(_ connection: Connection) async {
        do {
            try await connectionRepository.delete(id: connection.id)
            // Delete credentials based on connection type
            if connection.connectionType == .s3 {
                try? keychainService.deleteS3Credentials(for: connection.id)
            } else {
                try? keychainService.deletePassword(for: connection.id)
            }
            if selectedConnectionId == connection.id {
                selectedConnectionId = nil
            }
            await loadData()
            AnalyticsService.track(.connectionDeleted, with: [
                "protocol": AnalyticsService.ConnectionProtocol(from: connection.connectionType).rawValue
            ])
            logInfo("Connection deleted: \(connection.name)", category: .database)
        } catch {
            logError("Failed to delete connection: \(error)", category: .database)
            self.error = AppError.from(error)
        }
    }

    func moveConnection(_ connection: Connection, to folder: Folder?) async {
        do {
            try await connectionRepository.move(connectionId: connection.id, toFolderId: folder?.id)
            await loadData()
            logInfo("Connection moved: \(connection.name)", category: .database)
        } catch {
            logError("Failed to move connection: \(error)", category: .database)
            self.error = AppError.from(error)
        }
    }

    // MARK: - Folder Actions

    func createFolder(name: String) async {
        let nextOrder = (folders.map(\.displayOrder).max() ?? -1) + 1
        let folder = Folder(name: name, displayOrder: nextOrder)

        do {
            try await folderRepository.save(folder)
            await loadData()
            isShowingNewFolderSheet = false
            AnalyticsService.track(.folderCreated)
            logInfo("Folder created: \(name)", category: .database)
        } catch {
            logError("Failed to create folder: \(error)", category: .database)
            self.error = AppError.from(error)
        }
    }

    func reorderFolders(from source: IndexSet, to destination: Int) {
        folders.move(fromOffsets: source, toOffset: destination)
        for (index, _) in folders.enumerated() {
            folders[index].displayOrder = index
        }
        Task {
            do {
                try await folderRepository.updateOrder(folders)
            } catch {
                logError("Failed to reorder folders: \(error)", category: .database)
                self.error = AppError.from(error)
            }
        }
    }

    func renameFolder(_ folder: Folder, to newName: String) async {
        var updatedFolder = folder
        updatedFolder.name = newName

        do {
            try await folderRepository.update(updatedFolder)
            await loadData()
            logInfo("Folder renamed: \(newName)", category: .database)
        } catch {
            logError("Failed to rename folder: \(error)", category: .database)
            self.error = AppError.from(error)
        }
    }

    func deleteFolder(_ folder: Folder) async {
        do {
            try await folderRepository.delete(id: folder.id)
            if case .folder(let id) = selectedSidebarItem, id == folder.id {
                selectedSidebarItem = .allConnections
            }
            await loadData()
            isShowingDeleteFolderAlert = false
            folderToDelete = nil
            AnalyticsService.track(.folderDeleted)
            logInfo("Folder deleted: \(folder.name)", category: .database)
        } catch {
            logError("Failed to delete folder: \(error)", category: .database)
            self.error = AppError.from(error)
        }
    }

    // MARK: - Connection Operations

    func connectToServer(_ connection: Connection) {
        logInfo("Connect requested for: \(connection.name)", category: .ui)

        Task { @MainActor in
            // Gate connection behind biometric auth if configured
            let allowed = await AppLockManager.shared.authenticateForConnection()
            guard allowed else {
                logInfo("Connection cancelled: biometric auth denied", category: .auth)
                return
            }

            connectionToConnect = connection

            if connection.connectionType == .s3 {
                // For S3, check for saved credentials
                if let credentials = keychainService.getS3Credentials(for: connection.id) {
                    logInfo("Found saved S3 credentials, opening browser", category: .ui)
                    openFileBrowser(for: connection, password: credentials.secretAccessKey)
                } else {
                    logInfo("No saved S3 credentials, showing prompt", category: .ui)
                    isShowingPasswordPrompt = true
                }
            } else {
                // For SFTP, check for saved password
                if let savedPassword = keychainService.getPassword(for: connection.id) {
                    logInfo("Found saved password, opening browser", category: .ui)
                    openFileBrowser(for: connection, password: savedPassword)
                } else if connection.authMethod == .privateKey {
                    // Key-based auth doesn't require a password — connect directly
                    logInfo("Private key auth, connecting without password", category: .ui)
                    openFileBrowser(for: connection, password: "")
                } else {
                    logInfo("No saved password, showing prompt", category: .ui)
                    isShowingPasswordPrompt = true
                }
            }
        }
    }

    func connectWithPassword(_ password: String) {
        guard let connection = connectionToConnect else { return }
        openFileBrowser(for: connection, password: password)
        isShowingPasswordPrompt = false
        connectionToConnect = nil
    }

    func cancelConnect() {
        isShowingPasswordPrompt = false
        connectionToConnect = nil
    }

    private func openFileBrowser(for connection: Connection, password: String) {
        let data = FileBrowserWindowData(
            connectionId: connection.id,
            connectionName: connection.name,
            host: connection.host,
            port: connection.port,
            username: connection.username,
            password: password,
            authMethod: connection.authMethod,
            privateKeyPath: connection.privateKeyPath,
            connectionType: connection.connectionType,
            s3Region: connection.s3Region,
            s3Bucket: connection.s3Bucket,
            s3Endpoint: connection.s3Endpoint,
            s3SecretAccessKey: connection.connectionType == .s3 ? password : nil
        )

        let windowId = windowManager.storeFileBrowserData(data)
        logInfo("Stored window data with ID: \(windowId)", category: .ui)
        pendingWindowId = windowId
        AnalyticsService.trackConnectionConnected(protocol: .init(from: connection.connectionType), success: true)
        logInfo("Set pendingWindowId to: \(windowId)", category: .ui)
    }

    func clearPendingWindow() {
        pendingWindowId = nil
    }

    func clearPendingTerminalWindow() {
        pendingTerminalWindowId = nil
    }

    // MARK: - Terminal Operations

    func openTerminal(for connection: Connection, password: String) {
        // Only allow terminal for SFTP connections
        guard connection.connectionType == .sftp else {
            logWarning("Terminal only supported for SFTP connections", category: .ui)
            return
        }

        let data = TerminalWindowData(
            connectionId: connection.id,
            connectionName: connection.name,
            host: connection.host,
            port: connection.port,
            username: connection.username,
            password: password,
            authMethod: connection.authMethod,
            privateKeyPath: connection.privateKeyPath
        )

        let windowId = windowManager.storeTerminalData(data)
        logInfo("Stored terminal window data with ID: \(windowId)", category: .ui)
        pendingTerminalWindowId = windowId
    }

    func requestTerminal(for connection: Connection) {
        if connection.connectionType == .s3 {
            logWarning("Terminal not supported for S3 connections", category: .ui)
            return
        }

        Task { @MainActor in
            // Gate terminal behind biometric auth if configured
            let allowed = await AppLockManager.shared.authenticateForConnection()
            guard allowed else {
                logInfo("Terminal cancelled: biometric auth denied", category: .auth)
                return
            }

            connectionToConnect = connection

            // Check for saved password
            if let savedPassword = keychainService.getPassword(for: connection.id) {
                openTerminal(for: connection, password: savedPassword)
            } else if connection.authMethod == .privateKey {
                // Key-based auth doesn't require a password — connect directly
                logInfo("Private key auth, opening terminal without password", category: .ui)
                openTerminal(for: connection, password: "")
            } else {
                // Need to prompt for password
                isShowingPasswordPrompt = true
            }
        }
    }

    func openTerminalWithPassword(_ password: String) {
        guard let connection = connectionToConnect else { return }
        openTerminal(for: connection, password: password)
        isShowingPasswordPrompt = false
        connectionToConnect = nil
    }

    // MARK: - Edit Actions

    func editConnection(_ connection: Connection) {
        connectionToEdit = connection
        isShowingEditConnectionSheet = true
    }

    func duplicateConnection(_ connection: Connection) async {
        let newConnection = Connection(
            name: "\(connection.name) Copy",
            host: connection.host,
            port: connection.port,
            username: connection.username,
            authMethod: connection.authMethod,
            privateKeyPath: connection.privateKeyPath,
            savePassword: connection.savePassword,
            description: connection.description,
            tags: connection.tags,
            iconName: connection.iconName,
            folderId: connection.folderId,
            connectionType: connection.connectionType,
            s3Region: connection.s3Region,
            s3Bucket: connection.s3Bucket,
            s3Endpoint: connection.s3Endpoint
        )

        // Copy password if saved
        if connection.savePassword, let password = keychainService.getPassword(for: connection.id) {
            await saveConnection(newConnection, password: password)
        } else {
            await saveConnection(newConnection, password: nil)
        }
    }

    // MARK: - UI Actions

    func confirmDeleteFolder(_ folder: Folder) {
        folderToDelete = folder
        isShowingDeleteFolderAlert = true
    }

    func cancelDeleteFolder() {
        folderToDelete = nil
        isShowingDeleteFolderAlert = false
    }

    func clearError() {
        error = nil
    }

    func getSavedPassword(for connection: Connection) -> String? {
        keychainService.getPassword(for: connection.id)
    }
}
