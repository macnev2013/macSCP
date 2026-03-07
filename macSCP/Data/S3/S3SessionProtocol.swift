//
//  S3SessionProtocol.swift
//  macSCP
//
//  Protocol for S3 session operations
//

import Foundation

protocol S3SessionProtocol: Sendable {
    /// Whether the session is currently connected
    var isConnected: Bool { get async }

    /// Current working directory (bucket prefix)
    var currentPath: String { get async }

    /// Current bucket name
    var bucketName: String { get async }

    /// Connect to S3 with credentials
    func connect(
        accessKeyId: String,
        secretAccessKey: String,
        region: String,
        bucket: String,
        endpoint: String?
    ) async throws

    /// Disconnect from S3
    func disconnect() async

    /// List objects in a directory (prefix)
    func listFiles(at path: String) async throws -> [RemoteFile]

    /// Get object metadata
    func getFileInfo(at path: String) async throws -> RemoteFile

    /// Create a "directory" (marker object with trailing slash)
    func createDirectory(at path: String) async throws

    /// Create an empty file
    func createFile(at path: String) async throws

    /// Delete an object
    func deleteFile(at path: String) async throws

    /// Delete a "directory" and all its contents
    func deleteDirectory(at path: String) async throws

    /// Rename/move an object (copy + delete)
    func rename(from sourcePath: String, to destinationPath: String) async throws

    /// Copy an object
    func copyFile(from sourcePath: String, to destinationPath: String) async throws

    /// Copy a "directory" and all its contents
    func copyDirectory(from sourcePath: String, to destinationPath: String) async throws

    /// Move an object (copy + delete)
    func move(from sourcePath: String, to destinationPath: String) async throws

    /// Download an object to local storage
    func downloadFile(from remotePath: String, to localURL: URL) async throws

    /// Download an object to local storage with progress reporting
    func downloadFile(from remotePath: String, to localURL: URL, progress: TransferProgressHandler?) async throws

    /// Upload a file to S3
    func uploadFile(from localURL: URL, to remotePath: String) async throws

    /// Upload a file to S3 with progress reporting
    func uploadFile(from localURL: URL, to remotePath: String, progress: TransferProgressHandler?) async throws

    /// Read object content as string
    func readFileContent(at path: String) async throws -> String

    /// Write string content to an object
    func writeFileContent(_ content: String, to path: String) async throws

    /// Get the absolute path (just returns the path for S3)
    func getRealPath(at path: String) async throws -> String
}
