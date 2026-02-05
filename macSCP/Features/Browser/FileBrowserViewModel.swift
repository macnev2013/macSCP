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

    // MARK: - Transfer Progress State
    private(set) var activeTransfers: [UUID: TransferProgress] = [:]
    private(set) var recentTransfers: [TransferProgress] = []  // Completed/failed transfers
    private var transferTasks: [UUID: Task<Void, Never>] = [:]  // Tasks for cancellation
    var isShowingTransfersPopover: Bool = false

    /// Whether any transfer is currently in progress
    var hasActiveTransfers: Bool {
        !activeTransfers.isEmpty
    }

    /// Total number of active transfers
    var activeTransferCount: Int {
        activeTransfers.count
    }

    /// All transfers for display (active + recent)
    var allTransfers: [TransferProgress] {
        let active = activeTransfers.values.sorted { $0.startTime > $1.startTime }
        return active + recentTransfers
    }

    /// Overall progress of all active transfers (0.0 to 1.0)
    var overallProgress: Double {
        guard !activeTransfers.isEmpty else { return 0 }
        let totalBytes = activeTransfers.values.reduce(0) { $0 + $1.totalBytes }
        let transferredBytes = activeTransfers.values.reduce(0) { $0 + $1.bytesTransferred }
        guard totalBytes > 0 else { return 0 }
        return Double(transferredBytes) / Double(totalBytes)
    }

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
    var pendingTerminalWindowId: String?

    // MARK: - Connection Info
    let connection: Connection
    private let password: String

    // MARK: - Dependencies
    private let sftpSession: SFTPSessionProtocol?
    private let s3Session: S3SessionProtocol?
    private let fileRepository: FileRepositoryProtocol
    private let clipboardService: ClipboardService
    private let navigationService = NavigationService()

    // MARK: - Initialization (SFTP)
    init(
        connection: Connection,
        sftpSession: SFTPSessionProtocol,
        fileRepository: FileRepositoryProtocol,
        clipboardService: ClipboardService,
        password: String
    ) {
        self.connection = connection
        self.sftpSession = sftpSession
        self.s3Session = nil
        self.fileRepository = fileRepository
        self.clipboardService = clipboardService
        self.password = password
    }

    // MARK: - Initialization (S3)
    init(
        connection: Connection,
        s3Session: S3SessionProtocol,
        fileRepository: FileRepositoryProtocol,
        clipboardService: ClipboardService,
        secretAccessKey: String
    ) {
        self.connection = connection
        self.sftpSession = nil
        self.s3Session = s3Session
        self.fileRepository = fileRepository
        self.clipboardService = clipboardService
        self.password = secretAccessKey
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
            if connection.connectionType == .s3 {
                // S3 connection
                guard let s3Session = s3Session else {
                    throw AppError.notConnected
                }
                try await s3Session.connect(
                    accessKeyId: connection.username,
                    secretAccessKey: password,
                    region: connection.s3Region ?? "us-east-1",
                    bucket: connection.s3Bucket ?? "",
                    endpoint: connection.s3Endpoint
                )
                isConnected = true
                currentPath = await s3Session.currentPath
                navigationService.reset(to: currentPath)
                AnalyticsService.trackFileBrowserOpened(protocol: .init(from: connection.connectionType))
                await loadFiles()
            } else {
                // SFTP connection
                guard let sftpSession = sftpSession else {
                    throw AppError.notConnected
                }
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
                AnalyticsService.trackFileBrowserOpened(protocol: .init(from: connection.connectionType))
                await loadFiles()
            }
        } catch {
            logError("Connection failed: \(error)", category: connection.connectionType == .s3 ? .s3 : .sftp)
            state = .error(AppError.from(error))
        }
    }

    func disconnect() async {
        if connection.connectionType == .s3 {
            await s3Session?.disconnect()
        } else {
            await sftpSession?.disconnect()
        }
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
            if connection.connectionType == .s3 {
                currentPath = await s3Session?.currentPath ?? "/"
            } else {
                currentPath = await sftpSession?.currentPath ?? "/"
            }
            state = .success(())
        } catch {
            logError("Failed to load files: \(error)", category: connection.connectionType == .s3 ? .s3 : .sftp)
            state = .error(AppError.from(error))
        }
    }

    func navigateTo(_ path: String) async {
        state = .loading

        do {
            files = try await fileRepository.listFiles(at: path)
            if connection.connectionType == .s3 {
                currentPath = await s3Session?.currentPath ?? "/"
            } else {
                currentPath = await sftpSession?.currentPath ?? "/"
            }
            navigationService.navigate(to: currentPath)
            selectedFiles.removeAll()
            state = .success(())
        } catch {
            logError("Failed to navigate to \(path): \(error)", category: connection.connectionType == .s3 ? .s3 : .sftp)
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
            if connection.connectionType == .s3 {
                currentPath = await s3Session?.currentPath ?? "/"
            } else {
                currentPath = await sftpSession?.currentPath ?? "/"
            }
            selectedFiles.removeAll()
            state = .success(())
        } catch {
            logError("Failed to navigate to \(path): \(error)", category: connection.connectionType == .s3 ? .s3 : .sftp)
            state = .error(AppError.from(error))
        }
    }

    // MARK: - File Operations

    func createFolder(name: String) async {
        let path = currentPath.appendingPathComponent(name)

        do {
            try await fileRepository.createDirectory(at: path)
            isShowingNewFolderSheet = false
            AnalyticsService.trackFileOperation(.createFolder, protocol: .init(from: connection.connectionType))
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
            AnalyticsService.trackFileOperation(.rename, protocol: .init(from: connection.connectionType))
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
        AnalyticsService.trackFileOperation(.delete, protocol: .init(from: connection.connectionType), count: files.count)
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
            AnalyticsService.trackFileDownloaded(protocol: .init(from: connection.connectionType), fileCount: 1, totalBytes: file.size)
            logInfo("Downloaded: \(file.name)", category: connection.connectionType == .s3 ? .s3 : .sftp)
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

        await uploadURLs(panel.urls)
    }

    /// Core upload method that handles multiple files with progress tracking
    private func uploadURLs(_ urls: [URL]) async {
        // Show the transfers popover when starting uploads
        if !urls.isEmpty {
            isShowingTransfersPopover = true
        }

        for url in urls {
            guard url.isFileURL else { continue }

            let remotePath = currentPath.appendingPathComponent(url.lastPathComponent)
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

            // Create transfer tracking entry
            let transferId = UUID()
            let transfer = TransferProgress(
                id: transferId,
                fileName: url.lastPathComponent,
                localURL: url,
                remotePath: remotePath,
                bytesTransferred: 0,
                totalBytes: fileSize,
                status: .inProgress
            )
            activeTransfers[transferId] = transfer

            // Create a task for this upload so it can be cancelled
            let uploadTask = Task { [weak self] in
                guard let self = self else { return }

                do {
                    // Check for cancellation before starting
                    try Task.checkCancellation()

                    try await self.fileRepository.upload(localURL: url, to: remotePath) { [weak self] bytesTransferred in
                        Task { @MainActor in
                            // Check if transfer was cancelled
                            guard self?.activeTransfers[transferId] != nil else { return }
                            self?.activeTransfers[transferId]?.bytesTransferred = bytesTransferred
                        }
                    }

                    // Check for cancellation after upload
                    try Task.checkCancellation()

                    // Mark as completed
                    await MainActor.run {
                        if var completedTransfer = self.activeTransfers.removeValue(forKey: transferId) {
                            completedTransfer.status = .completed
                            completedTransfer.bytesTransferred = fileSize
                            self.recentTransfers.insert(completedTransfer, at: 0)
                            // Keep only last 10 recent transfers
                            if self.recentTransfers.count > 10 {
                                self.recentTransfers = Array(self.recentTransfers.prefix(10))
                            }
                        }
                        self.transferTasks.removeValue(forKey: transferId)
                    }

                    AnalyticsService.trackFileUploaded(protocol: .init(from: self.connection.connectionType), fileCount: 1, totalBytes: fileSize)
                    logInfo("Uploaded: \(url.lastPathComponent)", category: self.connection.connectionType == .s3 ? .s3 : .sftp)

                } catch {
                    // Check if this was a cancellation (either direct CancellationError or Task was cancelled)
                    let isCancellation = error is CancellationError ||
                        Task.isCancelled ||
                        String(describing: error).contains("CancellationError")

                    if isCancellation {
                        // Mark as cancelled (if not already removed by cancelTransfer)
                        await MainActor.run {
                            if var cancelledTransfer = self.activeTransfers.removeValue(forKey: transferId) {
                                cancelledTransfer.status = .cancelled
                                self.recentTransfers.insert(cancelledTransfer, at: 0)
                            }
                            self.transferTasks.removeValue(forKey: transferId)
                        }
                        logInfo("Upload cancelled: \(url.lastPathComponent)", category: self.connection.connectionType == .s3 ? .s3 : .sftp)
                    } else {
                        // Mark as failed
                        await MainActor.run {
                            if var failedTransfer = self.activeTransfers.removeValue(forKey: transferId) {
                                failedTransfer.status = .failed
                                failedTransfer.error = error.localizedDescription
                                self.recentTransfers.insert(failedTransfer, at: 0)
                            }
                            self.transferTasks.removeValue(forKey: transferId)
                        }

                        logError("Upload failed: \(error)", category: self.connection.connectionType == .s3 ? .s3 : .sftp)
                        await MainActor.run {
                            self.error = AppError.from(error)
                        }
                    }
                }
            }

            transferTasks[transferId] = uploadTask

            // Wait for this upload to complete before starting the next one
            await uploadTask.value
        }

        await loadFiles()
    }

    /// Cancels an active transfer
    func cancelTransfer(_ transfer: TransferProgress) {
        guard transfer.isInProgress else { return }

        // Cancel the task
        if let task = transferTasks[transfer.id] {
            task.cancel()
        }

        // Immediately update UI to show cancelled state
        if var cancelledTransfer = activeTransfers.removeValue(forKey: transfer.id) {
            cancelledTransfer.status = .cancelled
            recentTransfers.insert(cancelledTransfer, at: 0)
        }
        transferTasks.removeValue(forKey: transfer.id)
    }

    /// Cancels all active transfers
    func cancelAllTransfers() {
        for (id, task) in transferTasks {
            task.cancel()
            if var cancelledTransfer = activeTransfers.removeValue(forKey: id) {
                cancelledTransfer.status = .cancelled
                recentTransfers.insert(cancelledTransfer, at: 0)
            }
        }
        transferTasks.removeAll()
    }

    // MARK: - Drag and Drop

    /// Downloads a file to a specific URL (used for drag-out file promises)
    func downloadFileToURL(_ file: RemoteFile, destinationURL: URL) async throws {
        try await fileRepository.download(remotePath: file.path, to: destinationURL)
        AnalyticsService.trackFileDownloaded(protocol: .init(from: connection.connectionType), fileCount: 1, totalBytes: file.size)
        logInfo("Downloaded via drag: \(file.name)", category: connection.connectionType == .s3 ? .s3 : .sftp)
    }

    /// Uploads files dropped from Finder into the current directory
    func uploadDroppedFiles(_ urls: [URL]) async {
        await uploadURLs(urls)
    }

    /// Clears completed/failed transfers from the list
    func clearCompletedTransfers() {
        recentTransfers.removeAll()
    }

    /// Removes a specific transfer from the recent list
    func removeTransfer(_ transfer: TransferProgress) {
        recentTransfers.removeAll { $0.id == transfer.id }
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
        AnalyticsService.track(.fileInfoOpened)
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
            privateKeyPath: connection.privateKeyPath,
            connectionType: connection.connectionType,
            s3Region: connection.s3Region,
            s3Bucket: connection.s3Bucket,
            s3Endpoint: connection.s3Endpoint
        )
        let windowId = WindowManager.shared.storeFileEditorData(data)
        pendingEditorWindowId = windowId
        AnalyticsService.trackEditorOpened(fileExtension: (file.name as NSString).pathExtension)
    }

    func clearPendingEditorWindow() {
        pendingEditorWindowId = nil
    }

    func clearPendingTerminalWindow() {
        pendingTerminalWindowId = nil
    }

    // MARK: - Terminal

    func openTerminal() {
        // Only supported for SFTP connections
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

        let windowId = WindowManager.shared.storeTerminalData(data)
        pendingTerminalWindowId = windowId
        logInfo("Opening terminal from file browser", category: .ui)
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
