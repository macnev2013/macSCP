//
//  MockSFTPSession.swift
//  macSCPTests
//
//  Mock implementation of SFTPSessionProtocol for testing
//

import Foundation
@testable import macSCP

actor MockSFTPSession: SFTPSessionProtocol {
    // MARK: - State
    private(set) var isConnected = false
    private(set) var currentPath = "/"

    // MARK: - Recorded Calls
    var connectPasswordCalled = false
    var connectKeyCalled = false
    var disconnectCalled = false
    var listFilesCalled = false
    var getFileInfoCalled = false
    var createDirectoryCalled = false
    var createFileCalled = false
    var deleteFileCalled = false
    var deleteDirectoryCalled = false
    var renameCalled = false
    var copyFileCalled = false
    var copyDirectoryCalled = false
    var moveCalled = false
    var downloadFileCalled = false
    var uploadFileCalled = false
    var readFileContentCalled = false
    var writeFileContentCalled = false
    var getRealPathCalled = false
    var executeCommandCalled = false

    // MARK: - Mock Responses
    var mockFiles: [RemoteFile] = []
    var mockFileInfo: RemoteFile?
    var mockFileContent: String = ""
    var mockRealPath: String = "/home/user"
    var mockCommandOutput: String = ""
    var mockError: Error?

    // MARK: - Protocol Implementation

    func connect(host: String, port: Int, username: String, password: String) async throws {
        connectPasswordCalled = true
        if let error = mockError { throw error }
        isConnected = true
        currentPath = mockRealPath
    }

    func connect(host: String, port: Int, username: String, privateKeyPath: String, passphrase: String?) async throws {
        connectKeyCalled = true
        if let error = mockError { throw error }
        isConnected = true
        currentPath = mockRealPath
    }

    func disconnect() async {
        disconnectCalled = true
        isConnected = false
        currentPath = "/"
    }

    func listFiles(at path: String) async throws -> [RemoteFile] {
        listFilesCalled = true
        if let error = mockError { throw error }
        currentPath = path
        return mockFiles
    }

    func getFileInfo(at path: String) async throws -> RemoteFile {
        getFileInfoCalled = true
        if let error = mockError { throw error }
        guard let file = mockFileInfo else {
            throw AppError.fileNotFound
        }
        return file
    }

    func createDirectory(at path: String) async throws {
        createDirectoryCalled = true
        if let error = mockError { throw error }
    }

    func createFile(at path: String) async throws {
        createFileCalled = true
        if let error = mockError { throw error }
    }

    func deleteFile(at path: String) async throws {
        deleteFileCalled = true
        if let error = mockError { throw error }
    }

    func deleteDirectory(at path: String) async throws {
        deleteDirectoryCalled = true
        if let error = mockError { throw error }
    }

    func rename(from sourcePath: String, to destinationPath: String) async throws {
        renameCalled = true
        if let error = mockError { throw error }
    }

    func copyFile(from sourcePath: String, to destinationPath: String) async throws {
        copyFileCalled = true
        if let error = mockError { throw error }
    }

    func copyDirectory(from sourcePath: String, to destinationPath: String) async throws {
        copyDirectoryCalled = true
        if let error = mockError { throw error }
    }

    func move(from sourcePath: String, to destinationPath: String) async throws {
        moveCalled = true
        if let error = mockError { throw error }
    }

    func downloadFile(from remotePath: String, to localURL: URL) async throws {
        downloadFileCalled = true
        if let error = mockError { throw error }
    }

    func uploadFile(from localURL: URL, to remotePath: String) async throws {
        uploadFileCalled = true
        if let error = mockError { throw error }
    }

    func readFileContent(at path: String) async throws -> String {
        readFileContentCalled = true
        if let error = mockError { throw error }
        return mockFileContent
    }

    func writeFileContent(_ content: String, to path: String) async throws {
        writeFileContentCalled = true
        if let error = mockError { throw error }
    }

    func getRealPath(at path: String) async throws -> String {
        getRealPathCalled = true
        if let error = mockError { throw error }
        return mockRealPath
    }

    func executeCommand(_ command: String) async throws -> String {
        executeCommandCalled = true
        if let error = mockError { throw error }
        return mockCommandOutput
    }

    // MARK: - Reset
    func reset() {
        isConnected = false
        currentPath = "/"

        connectPasswordCalled = false
        connectKeyCalled = false
        disconnectCalled = false
        listFilesCalled = false
        getFileInfoCalled = false
        createDirectoryCalled = false
        createFileCalled = false
        deleteFileCalled = false
        deleteDirectoryCalled = false
        renameCalled = false
        copyFileCalled = false
        copyDirectoryCalled = false
        moveCalled = false
        downloadFileCalled = false
        uploadFileCalled = false
        readFileContentCalled = false
        writeFileContentCalled = false
        getRealPathCalled = false
        executeCommandCalled = false

        mockFiles = []
        mockFileInfo = nil
        mockFileContent = ""
        mockRealPath = "/home/user"
        mockCommandOutput = ""
        mockError = nil
    }
}
