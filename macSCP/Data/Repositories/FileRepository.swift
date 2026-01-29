//
//  FileRepository.swift
//  macSCP
//
//  Repository implementation for SFTP file operations
//

import Foundation

final class FileRepository: FileRepositoryProtocol, @unchecked Sendable {
    private let sftpSession: SFTPSessionProtocol

    init(sftpSession: SFTPSessionProtocol) {
        self.sftpSession = sftpSession
    }

    func listFiles(at path: String) async throws -> [RemoteFile] {
        try await sftpSession.listFiles(at: path)
    }

    func getFileInfo(at path: String) async throws -> RemoteFile {
        try await sftpSession.getFileInfo(at: path)
    }

    func createDirectory(at path: String) async throws {
        try await sftpSession.createDirectory(at: path)
    }

    func createFile(at path: String) async throws {
        try await sftpSession.createFile(at: path)
    }

    func delete(at path: String, isDirectory: Bool) async throws {
        if isDirectory {
            try await sftpSession.deleteDirectory(at: path)
        } else {
            try await sftpSession.deleteFile(at: path)
        }
    }

    func rename(from sourcePath: String, to destinationPath: String) async throws {
        try await sftpSession.rename(from: sourcePath, to: destinationPath)
    }

    func copy(from sourcePath: String, to destinationPath: String, isDirectory: Bool) async throws {
        if isDirectory {
            try await sftpSession.copyDirectory(from: sourcePath, to: destinationPath)
        } else {
            try await sftpSession.copyFile(from: sourcePath, to: destinationPath)
        }
    }

    func move(from sourcePath: String, to destinationPath: String) async throws {
        try await sftpSession.move(from: sourcePath, to: destinationPath)
    }

    func download(remotePath: String, to localURL: URL) async throws {
        try await sftpSession.downloadFile(from: remotePath, to: localURL)
    }

    func upload(localURL: URL, to remotePath: String) async throws {
        try await sftpSession.uploadFile(from: localURL, to: remotePath)
    }

    func readFileContent(at path: String) async throws -> String {
        try await sftpSession.readFileContent(at: path)
    }

    func writeFileContent(_ content: String, to path: String) async throws {
        try await sftpSession.writeFileContent(content, to: path)
    }

    func getRealPath(at path: String) async throws -> String {
        try await sftpSession.getRealPath(at: path)
    }
}
