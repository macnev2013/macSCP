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
    var selectedConnections: Set<UUID> = []

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
                try keychainService.savePassword(password, for: connection.id)
            }

            await loadData()
            isShowingNewConnectionSheet = false
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
                try keychainService.updatePassword(password, for: connection.id)
            } else if !connection.savePassword {
                try? keychainService.deletePassword(for: connection.id)
            }

            await loadData()
            isShowingEditConnectionSheet = false
            connectionToEdit = nil
            logInfo("Connection updated: \(connection.name)", category: .database)
        } catch {
            logError("Failed to update connection: \(error)", category: .database)
            self.error = AppError.from(error)
        }
    }

    func deleteConnection(_ connection: Connection) async {
        do {
            try await connectionRepository.delete(id: connection.id)
            try? keychainService.deletePassword(for: connection.id)
            await loadData()
            logInfo("Connection deleted: \(connection.name)", category: .database)
        } catch {
            logError("Failed to delete connection: \(error)", category: .database)
            self.error = AppError.from(error)
        }
    }

    func deleteSelectedConnections() async {
        for id in selectedConnections {
            if let connection = connections.first(where: { $0.id == id }) {
                await deleteConnection(connection)
            }
        }
        selectedConnections.removeAll()
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
        let folder = Folder(name: name)

        do {
            try await folderRepository.save(folder)
            await loadData()
            isShowingNewFolderSheet = false
            logInfo("Folder created: \(name)", category: .database)
        } catch {
            logError("Failed to create folder: \(error)", category: .database)
            self.error = AppError.from(error)
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
            logInfo("Folder deleted: \(folder.name)", category: .database)
        } catch {
            logError("Failed to delete folder: \(error)", category: .database)
            self.error = AppError.from(error)
        }
    }

    // MARK: - Connection Operations

    func connectToServer(_ connection: Connection) {
        logInfo("Connect requested for: \(connection.name)", category: .ui)
        connectionToConnect = connection

        // Check if we have a saved password
        if let savedPassword = keychainService.getPassword(for: connection.id) {
            logInfo("Found saved password, opening browser", category: .ui)
            openFileBrowser(for: connection, password: savedPassword)
        } else {
            logInfo("No saved password, showing prompt", category: .ui)
            isShowingPasswordPrompt = true
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
            privateKeyPath: connection.privateKeyPath
        )

        let windowId = windowManager.storeFileBrowserData(data)
        logInfo("Stored window data with ID: \(windowId)", category: .ui)
        pendingWindowId = windowId
        logInfo("Set pendingWindowId to: \(windowId)", category: .ui)
    }

    func clearPendingWindow() {
        pendingWindowId = nil
    }

    // MARK: - Edit Actions

    func editConnection(_ connection: Connection) {
        connectionToEdit = connection
        isShowingEditConnectionSheet = true
    }

    func duplicateConnection(_ connection: Connection) async {
        var newConnection = connection
        newConnection = Connection(
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
            folderId: connection.folderId
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
