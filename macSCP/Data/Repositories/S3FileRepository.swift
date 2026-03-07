//
//  S3FileRepository.swift
//  macSCP
//
//  Repository implementation for S3 file operations
//

import Foundation

final class S3FileRepository: FileRepositoryProtocol, @unchecked Sendable {
    private let s3Session: S3SessionProtocol

    init(s3Session: S3SessionProtocol) {
        self.s3Session = s3Session
    }

    func listFiles(at path: String) async throws -> [RemoteFile] {
        try await s3Session.listFiles(at: path)
    }

    func getFileInfo(at path: String) async throws -> RemoteFile {
        try await s3Session.getFileInfo(at: path)
    }

    func createDirectory(at path: String) async throws {
        try await s3Session.createDirectory(at: path)
    }

    func createFile(at path: String) async throws {
        try await s3Session.createFile(at: path)
    }

    func delete(at path: String, isDirectory: Bool) async throws {
        if isDirectory {
            try await s3Session.deleteDirectory(at: path)
        } else {
            try await s3Session.deleteFile(at: path)
        }
    }

    func rename(from sourcePath: String, to destinationPath: String) async throws {
        try await s3Session.rename(from: sourcePath, to: destinationPath)
    }

    func copy(from sourcePath: String, to destinationPath: String, isDirectory: Bool) async throws {
        if isDirectory {
            try await s3Session.copyDirectory(from: sourcePath, to: destinationPath)
        } else {
            try await s3Session.copyFile(from: sourcePath, to: destinationPath)
        }
    }

    func move(from sourcePath: String, to destinationPath: String) async throws {
        try await s3Session.move(from: sourcePath, to: destinationPath)
    }

    func download(remotePath: String, to localURL: URL) async throws {
        try await s3Session.downloadFile(from: remotePath, to: localURL)
    }

    func download(remotePath: String, to localURL: URL, progress: TransferProgressHandler?) async throws {
        try await s3Session.downloadFile(from: remotePath, to: localURL, progress: progress)
    }

    func upload(localURL: URL, to remotePath: String) async throws {
        try await s3Session.uploadFile(from: localURL, to: remotePath)
    }

    func upload(localURL: URL, to remotePath: String, progress: TransferProgressHandler?) async throws {
        try await s3Session.uploadFile(from: localURL, to: remotePath, progress: progress)
    }

    func readFileContent(at path: String) async throws -> String {
        try await s3Session.readFileContent(at: path)
    }

    func writeFileContent(_ content: String, to path: String) async throws {
        try await s3Session.writeFileContent(content, to: path)
    }

    func getRealPath(at path: String) async throws -> String {
        try await s3Session.getRealPath(at: path)
    }
}
