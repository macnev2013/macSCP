//
//  FileRepositoryProtocol.swift
//  macSCP
//
//  Protocol for SFTP file operations
//

import Foundation

protocol FileRepositoryProtocol: Sendable {
    /// Lists files in a directory
    func listFiles(at path: String) async throws -> [RemoteFile]

    /// Gets file attributes
    func getFileInfo(at path: String) async throws -> RemoteFile

    /// Creates a directory
    func createDirectory(at path: String) async throws

    /// Creates an empty file
    func createFile(at path: String) async throws

    /// Deletes a file or directory
    func delete(at path: String, isDirectory: Bool) async throws

    /// Renames a file or directory
    func rename(from sourcePath: String, to destinationPath: String) async throws

    /// Copies a file or directory
    func copy(from sourcePath: String, to destinationPath: String, isDirectory: Bool) async throws

    /// Moves a file or directory
    func move(from sourcePath: String, to destinationPath: String) async throws

    /// Downloads a file to local storage
    func download(remotePath: String, to localURL: URL) async throws

    /// Uploads a file from local storage
    func upload(localURL: URL, to remotePath: String) async throws

    /// Reads file content as string (for text files)
    func readFileContent(at path: String) async throws -> String

    /// Writes string content to a file
    func writeFileContent(_ content: String, to path: String) async throws

    /// Gets the real path (resolves symlinks and ~)
    func getRealPath(at path: String) async throws -> String
}
