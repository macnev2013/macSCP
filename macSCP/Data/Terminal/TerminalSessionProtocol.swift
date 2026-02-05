//
//  TerminalSessionProtocol.swift
//  macSCP
//
//  Protocol defining the terminal session interface
//

import Foundation

/// Size of the terminal in characters
struct TerminalSize: Sendable, Equatable {
    let columns: Int
    let rows: Int

    static let `default` = TerminalSize(columns: 80, rows: 24)
}

/// Protocol for terminal session implementations
protocol TerminalSessionProtocol: Sendable {
    /// Whether the session is currently connected
    var isConnected: Bool { get async }

    /// Connect to the server with password authentication
    /// - Parameters:
    ///   - host: The server hostname or IP address
    ///   - port: The SSH port (typically 22)
    ///   - username: The username for authentication
    ///   - password: The password for authentication
    ///   - terminalSize: Initial terminal dimensions
    func connect(
        host: String,
        port: Int,
        username: String,
        password: String,
        terminalSize: TerminalSize
    ) async throws

    /// Connect to the server with private key authentication
    /// - Parameters:
    ///   - host: The server hostname or IP address
    ///   - port: The SSH port (typically 22)
    ///   - username: The username for authentication
    ///   - privateKeyPath: Path to the private key file
    ///   - passphrase: Optional passphrase for the private key
    ///   - terminalSize: Initial terminal dimensions
    func connect(
        host: String,
        port: Int,
        username: String,
        privateKeyPath: String,
        passphrase: String?,
        terminalSize: TerminalSize
    ) async throws

    /// Send data to the terminal
    /// - Parameter data: The data to send (typically keyboard input)
    func send(_ data: Data) async throws

    /// Stream of output data from the terminal
    var outputStream: AsyncStream<Data> { get async }

    /// Resize the terminal
    /// - Parameters:
    ///   - columns: New width in characters
    ///   - rows: New height in characters
    func resize(columns: Int, rows: Int) async throws

    /// Disconnect from the server
    func disconnect() async
}
