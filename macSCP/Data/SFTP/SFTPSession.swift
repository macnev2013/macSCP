//
//  SFTPSession.swift
//  macSCP
//
//  Actor-based SFTP session using Citadel
//

import Foundation
import Citadel
import NIO
import NIOCore
import NIOFoundationCompat

actor SFTPSession: SFTPSessionProtocol {
    private var client: SSHClient?
    private var eventLoopGroup: MultiThreadedEventLoopGroup?
    private(set) var isConnected = false
    private(set) var currentPath = "/"

    init() {}

    // MARK: - Connection

    func connect(
        host: String,
        port: Int,
        username: String,
        password: String
    ) async throws {
        logInfo("Connecting to \(username)@\(host):\(port) with password", category: .sftp)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        eventLoopGroup = group

        do {
            // Normalize localhost to 127.0.0.1 to avoid IPv6 issues
            let normalizedHost = (host.lowercased() == "localhost") ? "127.0.0.1" : host

            let authMethod: SSHAuthenticationMethod = .passwordBased(
                username: username,
                password: password
            )

            client = try await SSHClient.connect(
                host: normalizedHost,
                port: port,
                authenticationMethod: authMethod,
                hostKeyValidator: .acceptAnything(),
                reconnect: .never,
                group: group
            )

            isConnected = true

            // Get home directory as initial path
            currentPath = try await getRealPath(at: ".")

            logInfo("Connected successfully to \(host)", category: .sftp)
        } catch {
            try? await group.shutdownGracefully()
            eventLoopGroup = nil
            throw parseConnectionError(error)
        }
    }

    func connect(
        host: String,
        port: Int,
        username: String,
        privateKeyPath: String,
        passphrase: String?
    ) async throws {
        logInfo("Connecting to \(username)@\(host):\(port) with private key", category: .sftp)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        eventLoopGroup = group

        do {
            let normalizedHost = (host.lowercased() == "localhost") ? "127.0.0.1" : host

            // Read the private key file
            let privateKeyURL = URL(fileURLWithPath: privateKeyPath)
            let privateKeyData = try Data(contentsOf: privateKeyURL)
            guard let privateKeyString = String(data: privateKeyData, encoding: .utf8) else {
                throw AppError.authenticationFailed
            }

            // Note: Citadel's RSA private key init doesn't support passphrase directly
            // For passphrase-protected keys, they need to be decrypted first or use OpenSSH format
            // The library expects unencrypted PEM or OpenSSH format keys
            let authMethod: SSHAuthenticationMethod = try .rsa(
                username: username,
                privateKey: .init(sshRsa: privateKeyString)
            )

            client = try await SSHClient.connect(
                host: normalizedHost,
                port: port,
                authenticationMethod: authMethod,
                hostKeyValidator: .acceptAnything(),
                reconnect: .never,
                group: group
            )

            isConnected = true
            currentPath = try await getRealPath(at: ".")

            logInfo("Connected successfully to \(host)", category: .sftp)
        } catch {
            try? await group.shutdownGracefully()
            eventLoopGroup = nil
            throw parseConnectionError(error)
        }
    }

    func disconnect() async {
        logInfo("Disconnecting from server", category: .sftp)

        try? await client?.close()
        try? await eventLoopGroup?.shutdownGracefully()

        client = nil
        eventLoopGroup = nil
        isConnected = false
        currentPath = "/"
    }

    // MARK: - File Operations

    func listFiles(at path: String) async throws -> [RemoteFile] {
        guard let client = client else {
            throw AppError.notConnected
        }

        let result = try await client.withSFTP { sftp in
            let actualPath = try await self.resolvePath(path, sftp: sftp)
            let listing = try await sftp.listDirectory(atPath: actualPath)

            var files: [RemoteFile] = []

            for nameResponse in listing {
                for component in nameResponse.components {
                    guard component.filename != ".", component.filename != ".." else { continue }

                    let fullPath = actualPath.hasSuffix("/")
                        ? "\(actualPath)\(component.filename)"
                        : "\(actualPath)/\(component.filename)"

                    let isDirectory = Self.isDirectoryFromPermissions(component.attributes.permissions)
                    let size = Int64(component.attributes.size ?? 0)
                    let permissions = Self.formatPermissions(component.attributes)
                    let modDate = component.attributes.accessModificationTime?.modificationTime

                    let file = RemoteFile(
                        name: component.filename,
                        path: fullPath,
                        isDirectory: isDirectory,
                        size: size,
                        permissions: permissions,
                        modificationDate: modDate
                    )

                    files.append(file)
                }
            }

            return (actualPath, files)
        }

        currentPath = result.0
        return RemoteFile.sortedFiles(result.1, by: .name)
    }

    func getFileInfo(at path: String) async throws -> RemoteFile {
        guard let client = client else {
            throw AppError.notConnected
        }

        let attributes = try await client.withSFTP { sftp in
            try await sftp.getAttributes(at: path)
        }

        let isDirectory = Self.isDirectoryFromPermissions(attributes.permissions)
        let size = Int64(attributes.size ?? 0)
        let permissions = Self.formatPermissions(attributes)
        let modDate = attributes.accessModificationTime?.modificationTime
        let fileName = (path as NSString).lastPathComponent

        return RemoteFile(
            name: fileName,
            path: path,
            isDirectory: isDirectory,
            size: size,
            permissions: permissions,
            modificationDate: modDate
        )
    }

    func createDirectory(at path: String) async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        do {
            try await client.withSFTP { sftp in
                try await sftp.createDirectory(atPath: path)
            }
            logInfo("Created directory: \(path)", category: .sftp)
        } catch {
            throw parseSFTPError(error, operation: "create directory")
        }
    }

    func createFile(at path: String) async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        do {
            try await client.withSFTP { sftp in
                try await sftp.withFile(filePath: path, flags: [.write, .create, .truncate]) { _ in }
            }
            logInfo("Created file: \(path)", category: .sftp)
        } catch {
            throw parseSFTPError(error, operation: "create file")
        }
    }

    func deleteFile(at path: String) async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        do {
            try await client.withSFTP { sftp in
                try await sftp.remove(at: path)
            }
            logInfo("Deleted file: \(path)", category: .sftp)
        } catch {
            throw parseSFTPError(error, operation: "delete file")
        }
    }

    func deleteDirectory(at path: String) async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        do {
            // Use rm -rf for recursive deletion
            let result = try await client.executeCommand("rm -rf '\(path)'")
            let output = String(buffer: result).trimmingCharacters(in: .whitespacesAndNewlines)

            if !output.isEmpty && output.lowercased().contains("permission denied") {
                throw AppError.permissionDenied
            }

            logInfo("Deleted directory: \(path)", category: .sftp)
        } catch let error as AppError {
            throw error
        } catch {
            throw parseSFTPError(error, operation: "delete directory")
        }
    }

    func rename(from sourcePath: String, to destinationPath: String) async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        do {
            try await client.withSFTP { sftp in
                try await sftp.rename(at: sourcePath, to: destinationPath)
            }
            logInfo("Renamed \(sourcePath) to \(destinationPath)", category: .sftp)
        } catch {
            throw parseSFTPError(error, operation: "rename")
        }
    }

    func copyFile(from sourcePath: String, to destinationPath: String) async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        do {
            let result = try await client.executeCommand("cp '\(sourcePath)' '\(destinationPath)'")
            let output = String(buffer: result).trimmingCharacters(in: .whitespacesAndNewlines)

            if !output.isEmpty && output.lowercased().contains("permission denied") {
                throw AppError.permissionDenied
            }

            logInfo("Copied file: \(sourcePath) to \(destinationPath)", category: .sftp)
        } catch let error as AppError {
            throw error
        } catch {
            throw parseSFTPError(error, operation: "copy file")
        }
    }

    func copyDirectory(from sourcePath: String, to destinationPath: String) async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        do {
            let result = try await client.executeCommand("cp -r '\(sourcePath)' '\(destinationPath)'")
            let output = String(buffer: result).trimmingCharacters(in: .whitespacesAndNewlines)

            if !output.isEmpty && output.lowercased().contains("permission denied") {
                throw AppError.permissionDenied
            }

            logInfo("Copied directory: \(sourcePath) to \(destinationPath)", category: .sftp)
        } catch let error as AppError {
            throw error
        } catch {
            throw parseSFTPError(error, operation: "copy directory")
        }
    }

    func move(from sourcePath: String, to destinationPath: String) async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        do {
            let result = try await client.executeCommand("mv '\(sourcePath)' '\(destinationPath)'")
            let output = String(buffer: result).trimmingCharacters(in: .whitespacesAndNewlines)

            if !output.isEmpty && output.lowercased().contains("permission denied") {
                throw AppError.permissionDenied
            }

            logInfo("Moved: \(sourcePath) to \(destinationPath)", category: .sftp)
        } catch let error as AppError {
            throw error
        } catch {
            throw parseSFTPError(error, operation: "move")
        }
    }

    func downloadFile(from remotePath: String, to localURL: URL) async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        do {
            try await client.withSFTP { sftp in
                try await sftp.withFile(filePath: remotePath, flags: .read) { file in
                    let buffer = try await file.readAll()
                    let data = Data(buffer: buffer)
                    try data.write(to: localURL)
                }
            }
            logInfo("Downloaded: \(remotePath) to \(localURL.path)", category: .sftp)
        } catch {
            throw parseSFTPError(error, operation: "download")
        }
    }

    func uploadFile(from localURL: URL, to remotePath: String) async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        do {
            let data = try Data(contentsOf: localURL)

            try await client.withSFTP { sftp in
                // Remove existing file if present
                try? await sftp.remove(at: remotePath)

                try await sftp.withFile(filePath: remotePath, flags: [.write, .create, .truncate]) { file in
                    try await file.write(ByteBuffer(data: data))
                }
            }
            logInfo("Uploaded: \(localURL.path) to \(remotePath)", category: .sftp)
        } catch {
            throw parseSFTPError(error, operation: "upload")
        }
    }

    func readFileContent(at path: String) async throws -> String {
        guard let client = client else {
            throw AppError.notConnected
        }

        return try await client.withSFTP { sftp in
            try await sftp.withFile(filePath: path, flags: .read) { file in
                let buffer = try await file.readAll()
                return String(buffer: buffer)
            }
        }
    }

    func writeFileContent(_ content: String, to path: String) async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        do {
            try await client.withSFTP { sftp in
                try? await sftp.remove(at: path)

                try await sftp.withFile(filePath: path, flags: [.write, .create, .truncate]) { file in
                    try await file.write(ByteBuffer(string: content))
                }
            }
            logInfo("Wrote content to: \(path)", category: .sftp)
        } catch {
            throw parseSFTPError(error, operation: "write file")
        }
    }

    func getRealPath(at path: String) async throws -> String {
        guard let client = client else {
            throw AppError.notConnected
        }

        return try await client.withSFTP { sftp in
            try await sftp.getRealPath(atPath: path)
        }
    }

    func executeCommand(_ command: String) async throws -> String {
        guard let client = client else {
            throw AppError.notConnected
        }

        let result = try await client.executeCommand(command)
        return String(buffer: result)
    }

    // MARK: - Private Helpers

    private func resolvePath(_ path: String, sftp: SFTPClient) async throws -> String {
        if path == "~" || path == "." {
            return try await sftp.getRealPath(atPath: ".")
        } else if path == ".." {
            let components = currentPath.split(separator: "/")
            if components.count > 1 {
                return "/" + components.dropLast().joined(separator: "/")
            }
            return "/"
        } else if path.hasPrefix("/") {
            return path
        } else {
            return currentPath.appendingPathComponent(path)
        }
    }

    private nonisolated static func isDirectoryFromPermissions(_ permissions: UInt32?) -> Bool {
        guard let permissions = permissions else { return false }
        return (permissions & 0o170000) == 0o040000
    }

    private nonisolated static func formatPermissions(_ attributes: SFTPFileAttributes) -> String {
        guard let permissions = attributes.permissions else {
            return "----------"
        }

        var result = ""

        let fileType = permissions & 0o170000
        switch fileType {
        case 0o040000: result += "d"
        case 0o120000: result += "l"
        case 0o100000: result += "-"
        case 0o060000: result += "b"
        case 0o020000: result += "c"
        case 0o010000: result += "p"
        case 0o140000: result += "s"
        default: result += "-"
        }

        result += (permissions & 0o400) != 0 ? "r" : "-"
        result += (permissions & 0o200) != 0 ? "w" : "-"
        result += (permissions & 0o100) != 0 ? "x" : "-"
        result += (permissions & 0o040) != 0 ? "r" : "-"
        result += (permissions & 0o020) != 0 ? "w" : "-"
        result += (permissions & 0o010) != 0 ? "x" : "-"
        result += (permissions & 0o004) != 0 ? "r" : "-"
        result += (permissions & 0o002) != 0 ? "w" : "-"
        result += (permissions & 0o001) != 0 ? "x" : "-"

        return result
    }

    private func parseConnectionError(_ error: Error) -> AppError {
        let description = error.localizedDescription.lowercased()

        if description.contains("connection refused") {
            return .connectionFailed("Connection refused. Make sure the SSH server is running.")
        } else if description.contains("host unreachable") || description.contains("no route to host") {
            return .hostUnreachable
        } else if description.contains("timeout") {
            return .connectionTimeout
        } else if description.contains("authentication") || description.contains("password") || description.contains("permission denied") {
            return .authenticationFailed
        } else if description.contains("operation not permitted") {
            return .connectionFailed("Operation not permitted. Check firewall settings.")
        }

        return .connectionFailed(error.localizedDescription)
    }

    private func parseSFTPError(_ error: Error, operation: String) -> AppError {
        let errorString = String(describing: error)

        if errorString.contains("SSH_FX_PERMISSION_DENIED") || errorString.contains("Permission denied") {
            return .permissionDenied
        } else if errorString.contains("SSH_FX_NO_SUCH_FILE") || errorString.contains("No such file") {
            return .fileNotFound
        } else if errorString.contains("SSH_FX_FILE_ALREADY_EXISTS") {
            return .fileAlreadyExists
        } else if errorString.contains("SSH_FX_FAILURE") {
            return .sftpOperationFailed("Operation failed on the server")
        } else if errorString.contains("SSH_FX_NO_CONNECTION") {
            return .connectionLost
        }

        return .sftpOperationFailed("Failed to \(operation): \(error.localizedDescription)")
    }
}
