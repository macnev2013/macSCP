//
//  FileBrowserViewModel.swift
//  macSCP
//
//  ViewModel for the file browser feature
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class FileBrowserViewModel {
    // MARK: - Published State
    private(set) var files: [RemoteFile] = []
    private(set) var state: ViewState<Void> = .idle
    private(set) var currentPath: String = "/"
    private(set) var isConnected: Bool = false
    var error: AppError?

    var selectedFiles: Set<UUID> = []
    var sortCriteria: RemoteFile.SortCriteria = .name
    var sortAscending: Bool = true
    var showHiddenFiles: Bool = false

    // Sheet states
    var isShowingNewFolderSheet = false
    var isShowingNewFileSheet = false
    var isShowingRenameSheet = false
    var isShowingDeleteConfirmation = false

    // File to operate on
    var fileToRename: RemoteFile?
    var filesToDelete: [RemoteFile] = []

    // Window opening state
    var pendingFileInfoWindowId: String?
    var pendingEditorWindowId: String?

    // MARK: - Connection Info
    let connection: Connection
    private let password: String

    // MARK: - Dependencies
    private let sftpSession: SFTPSessionProtocol
    private let fileRepository: FileRepositoryProtocol
    private let clipboardService: ClipboardService
    private let navigationService = NavigationService()

    // MARK: - Initialization
    init(
        connection: Connection,
        sftpSession: SFTPSessionProtocol,
        fileRepository: FileRepositoryProtocol,
        clipboardService: ClipboardService,
        password: String
    ) {
        self.connection = connection
        self.sftpSession = sftpSession
        self.fileRepository = fileRepository
        self.clipboardService = clipboardService
        self.password = password
    }

    // MARK: - Computed Properties

    var sortedFiles: [RemoteFile] {
        var result = files

        if !showHiddenFiles {
            result = result.filter { !$0.isHidden }
        }

        return RemoteFile.sortedFiles(result, by: sortCriteria, ascending: sortAscending)
    }

    var selectedFilesList: [RemoteFile] {
        files.filter { selectedFiles.contains($0.id) }
    }

    var canGoBack: Bool {
        navigationService.canGoBack
    }

    var canGoForward: Bool {
        navigationService.canGoForward
    }

    var canGoUp: Bool {
        currentPath != "/"
    }

    var pathComponents: [PathComponent] {
        var components: [PathComponent] = []
        var path = ""

        for component in currentPath.split(separator: "/") {
            path += "/" + component
            components.append(PathComponent(name: String(component), path: path))
        }

        if components.isEmpty {
            components.append(PathComponent(name: "/", path: "/"))
        }

        return components
    }

    var clipboardDisplayText: String {
        clipboardService.displayText
    }

    var hasClipboardItems: Bool {
        !clipboardService.isEmpty
    }

    var canPaste: Bool {
        clipboardService.canPaste(to: connection.id)
    }

    // MARK: - Connection

    func connect() async {
        state = .loading

        do {
            if connection.authMethod == .password {
                try await sftpSession.connect(
                    host: connection.host,
                    port: connection.port,
                    username: connection.username,
                    password: password
                )
            } else if let keyPath = connection.privateKeyPath {
                try await sftpSession.connect(
                    host: connection.host,
                    port: connection.port,
                    username: connection.username,
                    privateKeyPath: keyPath,
                    passphrase: password.isEmpty ? nil : password
                )
            }

            isConnected = true
            currentPath = await sftpSession.currentPath
            navigationService.reset(to: currentPath)
            await loadFiles()
        } catch {
            logError("Connection failed: \(error)", category: .sftp)
            state = .error(AppError.from(error))
        }
    }

    func disconnect() async {
        await sftpSession.disconnect()
        isConnected = false
        files = []
        currentPath = "/"
        navigationService.reset()
    }

    // MARK: - Navigation

    func loadFiles() async {
        state = .loading

        do {
            files = try await fileRepository.listFiles(at: currentPath)
            currentPath = await sftpSession.currentPath
            state = .success(())
        } catch {
            logError("Failed to load files: \(error)", category: .sftp)
            state = .error(AppError.from(error))
        }
    }

    func navigateTo(_ path: String) async {
        state = .loading

        do {
            files = try await fileRepository.listFiles(at: path)
            currentPath = await sftpSession.currentPath
            navigationService.navigate(to: currentPath)
            selectedFiles.removeAll()
            state = .success(())
        } catch {
            logError("Failed to navigate to \(path): \(error)", category: .sftp)
            state = .error(AppError.from(error))
        }
    }

    func openFile(_ file: RemoteFile) async {
        if file.isDirectory {
            await navigateTo(file.path)
        } else if FileTypeService.isPreviewable(file) {
            // Open in editor - handled by view
        }
    }

    func goBack() async {
        if let path = navigationService.goBack() {
            await navigateWithoutHistory(to: path)
        }
    }

    func goForward() async {
        if let path = navigationService.goForward() {
            await navigateWithoutHistory(to: path)
        }
    }

    func goUp() async {
        await navigateTo(currentPath.parentPath)
    }

    func goHome() async {
        await navigateTo("~")
    }

    func refresh() async {
        await loadFiles()
    }

    private func navigateWithoutHistory(to path: String) async {
        state = .loading

        do {
            files = try await fileRepository.listFiles(at: path)
            currentPath = await sftpSession.currentPath
            selectedFiles.removeAll()
            state = .success(())
        } catch {
            logError("Failed to navigate to \(path): \(error)", category: .sftp)
            state = .error(AppError.from(error))
        }
    }

    // MARK: - File Operations

    func createFolder(name: String) async {
        let path = currentPath.appendingPathComponent(name)

        do {
            try await fileRepository.createDirectory(at: path)
            isShowingNewFolderSheet = false
            await loadFiles()
        } catch {
            logError("Failed to create folder: \(error)", category: .sftp)
            self.error = AppError.from(error)
        }
    }

    func createFile(name: String) async {
        let path = currentPath.appendingPathComponent(name)

        do {
            try await fileRepository.createFile(at: path)
            isShowingNewFileSheet = false
            await loadFiles()
        } catch {
            logError("Failed to create file: \(error)", category: .sftp)
            self.error = AppError.from(error)
        }
    }

    func renameFile(_ file: RemoteFile, to newName: String) async {
        let newPath = file.path.directoryPath.appendingPathComponent(newName)

        do {
            try await fileRepository.rename(from: file.path, to: newPath)
            isShowingRenameSheet = false
            fileToRename = nil
            await loadFiles()
        } catch {
            logError("Failed to rename file: \(error)", category: .sftp)
            self.error = AppError.from(error)
        }
    }

    func deleteFiles(_ files: [RemoteFile]) async {
        for file in files {
            do {
                try await fileRepository.delete(at: file.path, isDirectory: file.isDirectory)
            } catch {
                logError("Failed to delete \(file.name): \(error)", category: .sftp)
                self.error = AppError.from(error)
                return
            }
        }

        isShowingDeleteConfirmation = false
        filesToDelete = []
        selectedFiles.removeAll()
        await loadFiles()
    }

    func deleteSelectedFiles() async {
        await deleteFiles(selectedFilesList)
    }

    // MARK: - Clipboard Operations

    func copySelectedFiles() {
        clipboardService.copy(files: selectedFilesList, from: currentPath, connectionId: connection.id)
    }

    func cutSelectedFiles() {
        clipboardService.cut(files: selectedFilesList, from: currentPath, connectionId: connection.id)
    }

    func paste() async {
        guard canPaste else { return }

        let items = clipboardService.items
        let isCut = clipboardService.isCut

        for item in items {
            let destinationPath = currentPath.appendingPathComponent(item.fileName)

            do {
                if isCut {
                    try await fileRepository.move(from: item.fullSourcePath, to: destinationPath)
                } else {
                    try await fileRepository.copy(
                        from: item.fullSourcePath,
                        to: destinationPath,
                        isDirectory: item.isDirectory
                    )
                }
            } catch {
                logError("Failed to paste \(item.fileName): \(error)", category: .sftp)
                self.error = AppError.from(error)
                return
            }
        }

        if isCut {
            clipboardService.clear()
        }

        await loadFiles()
    }

    // MARK: - Download/Upload

    func downloadFile(_ file: RemoteFile) async {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = file.name
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try await fileRepository.download(remotePath: file.path, to: url)
            logInfo("Downloaded: \(file.name)", category: .sftp)
        } catch {
            logError("Download failed: \(error)", category: .sftp)
            self.error = AppError.from(error)
        }
    }

    func uploadFiles() async {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK else { return }

        for url in panel.urls {
            let remotePath = currentPath.appendingPathComponent(url.lastPathComponent)

            do {
                try await fileRepository.upload(localURL: url, to: remotePath)
                logInfo("Uploaded: \(url.lastPathComponent)", category: .sftp)
            } catch {
                logError("Upload failed: \(error)", category: .sftp)
                self.error = AppError.from(error)
                return
            }
        }

        await loadFiles()
    }

    // MARK: - File Content

    func getFileContent(_ file: RemoteFile) async throws -> String {
        try await fileRepository.readFileContent(at: file.path)
    }

    func saveFileContent(_ content: String, to path: String) async throws {
        try await fileRepository.writeFileContent(content, to: path)
    }

    // MARK: - Selection

    func selectAll() {
        selectedFiles = Set(sortedFiles.map { $0.id })
    }

    func deselectAll() {
        selectedFiles.removeAll()
    }

    func toggleSelection(for file: RemoteFile) {
        if selectedFiles.contains(file.id) {
            selectedFiles.remove(file.id)
        } else {
            selectedFiles.insert(file.id)
        }
    }

    // MARK: - UI Actions

    func confirmDelete(_ files: [RemoteFile]) {
        filesToDelete = files
        isShowingDeleteConfirmation = true
    }

    func confirmDeleteSelected() {
        confirmDelete(selectedFilesList)
    }

    func startRename(_ file: RemoteFile) {
        fileToRename = file
        isShowingRenameSheet = true
    }

    func showFileInfo(_ file: RemoteFile) {
        let data = FileInfoWindowData(
            file: file,
            connectionName: connection.name
        )
        let windowId = WindowManager.shared.storeFileInfoData(data)
        pendingFileInfoWindowId = windowId
    }

    func clearPendingFileInfoWindow() {
        pendingFileInfoWindowId = nil
    }

    func openEditor(for file: RemoteFile, content: String) {
        let data = FileEditorWindowData(
            filePath: file.path,
            fileName: file.name,
            content: content,
            connectionId: connection.id,
            host: connection.host,
            port: connection.port,
            username: connection.username,
            password: password,
            authMethod: connection.authMethod,
            privateKeyPath: connection.privateKeyPath
        )
        let windowId = WindowManager.shared.storeFileEditorData(data)
        pendingEditorWindowId = windowId
    }

    func clearPendingEditorWindow() {
        pendingEditorWindowId = nil
    }

    func clearError() {
        error = nil
    }
}

// MARK: - Path Component
struct PathComponent: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let path: String

    static func == (lhs: PathComponent, rhs: PathComponent) -> Bool {
        lhs.path == rhs.path && lhs.name == rhs.name
    }
}
