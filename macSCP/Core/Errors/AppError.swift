//
//  AppError.swift
//  macSCP
//
//  Unified error types for the application
//

import Foundation

enum AppError: LocalizedError, Sendable {
    // Connection errors
    case connectionFailed(String)
    case connectionTimeout
    case connectionLost
    case authenticationFailed
    case hostUnreachable

    // SFTP errors
    case sftpOperationFailed(String)
    case permissionDenied
    case fileNotFound
    case fileAlreadyExists
    case directoryNotEmpty
    case invalidPath

    // S3 errors
    case s3BucketNotFound
    case s3AccessDenied
    case s3ObjectNotFound
    case s3OperationFailed(String)
    case invalidS3Credentials

    // Data errors
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    case entityNotFound

    // Keychain errors
    case keychainSaveFailed
    case keychainReadFailed
    case keychainDeleteFailed

    // File operation errors
    case downloadFailed(String)
    case uploadFailed(String)
    case fileReadFailed
    case fileWriteFailed

    // Terminal errors
    case terminalConnectionFailed(String)
    case terminalConnectionLost
    case terminalPTYFailed

    // General errors
    case unknown(String)
    case notConnected

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .connectionTimeout:
            return "Connection timed out"
        case .connectionLost:
            return "Connection was lost"
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .hostUnreachable:
            return "Host is unreachable. Check the hostname and network connection."

        case .sftpOperationFailed(let message):
            return "SFTP operation failed: \(message)"
        case .permissionDenied:
            return "Permission denied"
        case .fileNotFound:
            return "File or directory not found"
        case .fileAlreadyExists:
            return "A file or directory with this name already exists"
        case .directoryNotEmpty:
            return "Directory is not empty"
        case .invalidPath:
            return "Invalid path"

        case .s3BucketNotFound:
            return "S3 bucket not found"
        case .s3AccessDenied:
            return "Access denied to S3 resource"
        case .s3ObjectNotFound:
            return "S3 object not found"
        case .s3OperationFailed(let message):
            return "S3 operation failed: \(message)"
        case .invalidS3Credentials:
            return "Invalid S3 credentials"

        case .saveFailed(let message):
            return "Failed to save: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete: \(message)"
        case .entityNotFound:
            return "Entity not found"

        case .keychainSaveFailed:
            return "Failed to save password to keychain"
        case .keychainReadFailed:
            return "Failed to read password from keychain"
        case .keychainDeleteFailed:
            return "Failed to delete password from keychain"

        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .fileReadFailed:
            return "Failed to read file"
        case .fileWriteFailed:
            return "Failed to write file"

        case .terminalConnectionFailed(let message):
            return "Terminal connection failed: \(message)"
        case .terminalConnectionLost:
            return "Terminal connection was lost"
        case .terminalPTYFailed:
            return "Failed to allocate pseudo-terminal"

        case .unknown(let message):
            return message
        case .notConnected:
            return "Not connected to server"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .connectionFailed, .connectionTimeout, .hostUnreachable:
            return "Please check your network connection and server address."
        case .authenticationFailed:
            return "Please verify your username and password."
        case .permissionDenied, .s3AccessDenied:
            return "You don't have permission to perform this action."
        case .notConnected:
            return "Please connect to a server first."
        case .s3BucketNotFound:
            return "Please check your bucket name and region."
        case .invalidS3Credentials:
            return "Please verify your Access Key ID and Secret Access Key."
        case .terminalConnectionFailed, .terminalConnectionLost:
            return "Please check your network connection and try reconnecting."
        case .terminalPTYFailed:
            return "The server may not support interactive terminals. Please try again."
        default:
            return nil
        }
    }
}

// MARK: - Error Conversion
extension AppError {
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error.localizedDescription)
    }
}
