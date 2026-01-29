//
//  MockFileRepository.swift
//  macSCPTests
//
//  Mock implementation of FileRepositoryProtocol for testing
//

import Foundation
@testable import macSCP

final class MockFileRepository: FileRepositoryProtocol, @unchecked Sendable {
    // MARK: - Recorded Calls
    var listFilesCalled = false
    var getFileInfoCalled = false
    var createDirectoryCalled = false
    var createFileCalled = false
    var deleteCalled = false
    var renameCalled = false
    var copyCalled = false
    var moveCalled = false
    var downloadCalled = false
    var uploadCalled = false
    var readFileContentCalled = false
    var writeFileContentCalled = false
    var getRealPathCalled = false

    // MARK: - Recorded Parameters
    var lastListPath: String?
    var lastFileInfoPath: String?
    var lastCreateDirectoryPath: String?
    var lastCreateFilePath: String?
    var lastDeletePath: String?
    var lastRenameSourcePath: String?
    var lastRenameDestPath: String?
    var lastCopySourcePath: String?
    var lastCopyDestPath: String?
    var lastMoveSourcePath: String?
    var lastMoveDestPath: String?
    var lastDownloadRemotePath: String?
    var lastDownloadLocalURL: URL?
    var lastUploadLocalURL: URL?
    var lastUploadRemotePath: String?
    var lastReadPath: String?
    var lastWritePath: String?
    var lastWriteContent: String?
    var lastRealPath: String?

    // MARK: - Mock Responses
    var mockFiles: [RemoteFile] = []
    var mockFileInfo: RemoteFile?
    var mockFileContent: String = ""
    var mockRealPath: String = "/"
    var mockError: Error?

    // MARK: - Protocol Implementation

    func listFiles(at path: String) async throws -> [RemoteFile] {
        listFilesCalled = true
        lastListPath = path
        if let error = mockError { throw error }
        return mockFiles
    }

    func getFileInfo(at path: String) async throws -> RemoteFile {
        getFileInfoCalled = true
        lastFileInfoPath = path
        if let error = mockError { throw error }
        guard let file = mockFileInfo else {
            throw AppError.fileNotFound
        }
        return file
    }

    func createDirectory(at path: String) async throws {
        createDirectoryCalled = true
        lastCreateDirectoryPath = path
        if let error = mockError { throw error }
    }

    func createFile(at path: String) async throws {
        createFileCalled = true
        lastCreateFilePath = path
        if let error = mockError { throw error }
    }

    func delete(at path: String, isDirectory: Bool) async throws {
        deleteCalled = true
        lastDeletePath = path
        if let error = mockError { throw error }
    }

    func rename(from sourcePath: String, to destinationPath: String) async throws {
        renameCalled = true
        lastRenameSourcePath = sourcePath
        lastRenameDestPath = destinationPath
        if let error = mockError { throw error }
    }

    func copy(from sourcePath: String, to destinationPath: String, isDirectory: Bool) async throws {
        copyCalled = true
        lastCopySourcePath = sourcePath
        lastCopyDestPath = destinationPath
        if let error = mockError { throw error }
    }

    func move(from sourcePath: String, to destinationPath: String) async throws {
        moveCalled = true
        lastMoveSourcePath = sourcePath
        lastMoveDestPath = destinationPath
        if let error = mockError { throw error }
    }

    func download(remotePath: String, to localURL: URL) async throws {
        downloadCalled = true
        lastDownloadRemotePath = remotePath
        lastDownloadLocalURL = localURL
        if let error = mockError { throw error }
    }

    func upload(localURL: URL, to remotePath: String) async throws {
        uploadCalled = true
        lastUploadLocalURL = localURL
        lastUploadRemotePath = remotePath
        if let error = mockError { throw error }
    }

    func readFileContent(at path: String) async throws -> String {
        readFileContentCalled = true
        lastReadPath = path
        if let error = mockError { throw error }
        return mockFileContent
    }

    func writeFileContent(_ content: String, to path: String) async throws {
        writeFileContentCalled = true
        lastWriteContent = content
        lastWritePath = path
        if let error = mockError { throw error }
    }

    func getRealPath(at path: String) async throws -> String {
        getRealPathCalled = true
        lastRealPath = path
        if let error = mockError { throw error }
        return mockRealPath
    }

    // MARK: - Reset
    func reset() {
        listFilesCalled = false
        getFileInfoCalled = false
        createDirectoryCalled = false
        createFileCalled = false
        deleteCalled = false
        renameCalled = false
        copyCalled = false
        moveCalled = false
        downloadCalled = false
        uploadCalled = false
        readFileContentCalled = false
        writeFileContentCalled = false
        getRealPathCalled = false

        lastListPath = nil
        lastFileInfoPath = nil
        lastCreateDirectoryPath = nil
        lastCreateFilePath = nil
        lastDeletePath = nil
        lastRenameSourcePath = nil
        lastRenameDestPath = nil
        lastCopySourcePath = nil
        lastCopyDestPath = nil
        lastMoveSourcePath = nil
        lastMoveDestPath = nil
        lastDownloadRemotePath = nil
        lastDownloadLocalURL = nil
        lastUploadLocalURL = nil
        lastUploadRemotePath = nil
        lastReadPath = nil
        lastWritePath = nil
        lastWriteContent = nil
        lastRealPath = nil

        mockFiles = []
        mockFileInfo = nil
        mockFileContent = ""
        mockRealPath = "/"
        mockError = nil
    }
}
