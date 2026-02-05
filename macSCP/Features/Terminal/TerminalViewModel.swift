//
//  TerminalViewModel.swift
//  macSCP
//
//  ViewModel for the terminal feature
//

import Foundation
import SwiftUI

/// State of the terminal connection
enum TerminalState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case error(AppError)

    static func == (lhs: TerminalState, rhs: TerminalState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

@MainActor
@Observable
final class TerminalViewModel {
    // MARK: - Published State
    private(set) var state: TerminalState = .disconnected
    private(set) var isConnected: Bool = false
    var error: AppError?

    let connectionName: String

    // MARK: - Dependencies
    private let session: TerminalSessionProtocol
    private let connectionData: TerminalWindowData

    // MARK: - Output handling
    private var outputTask: Task<Void, Never>?
    private var pendingOutputBuffer: [Data] = []

    var onOutput: ((Data) -> Void)? {
        didSet {
            // When callback is set, flush any buffered data
            if let callback = onOutput {
                for data in pendingOutputBuffer {
                    callback(data)
                }
                pendingOutputBuffer.removeAll()
            }
        }
    }

    // MARK: - Terminal size
    private var currentSize: TerminalSize = .default

    // MARK: - Initialization

    init(
        connectionName: String,
        session: TerminalSessionProtocol,
        connectionData: TerminalWindowData
    ) {
        self.connectionName = connectionName
        self.session = session
        self.connectionData = connectionData
    }

    // MARK: - Connection

    func connect() async {
        // Only connect if disconnected or in error state
        switch state {
        case .disconnected, .error:
            break
        case .connecting, .connected:
            return
        }

        state = .connecting

        do {
            if connectionData.authMethod == .password {
                try await session.connect(
                    host: connectionData.host,
                    port: connectionData.port,
                    username: connectionData.username,
                    password: connectionData.password,
                    terminalSize: currentSize
                )
            } else if let keyPath = connectionData.privateKeyPath {
                try await session.connect(
                    host: connectionData.host,
                    port: connectionData.port,
                    username: connectionData.username,
                    privateKeyPath: keyPath,
                    passphrase: connectionData.password.isEmpty ? nil : connectionData.password,
                    terminalSize: currentSize
                )
            }

            isConnected = true
            state = .connected

            // Start listening for output
            startOutputListener()

            logInfo("Terminal connected to \(connectionData.host)", category: .network)
        } catch {
            logError("Terminal connection failed: \(error)", category: .network)
            let appError = AppError.from(error)
            state = .error(appError)
            self.error = appError
        }
    }

    func disconnect() async {
        outputTask?.cancel()
        outputTask = nil
        pendingOutputBuffer.removeAll()

        await session.disconnect()
        isConnected = false
        state = .disconnected

        logInfo("Terminal disconnected", category: .network)
    }

    func reconnect() async {
        await disconnect()
        await connect()
    }

    // MARK: - Input/Output

    func sendInput(_ data: Data) {
        guard isConnected else { return }

        Task {
            do {
                try await session.send(data)
            } catch {
                logError("Failed to send terminal input: \(error)", category: .network)
                self.error = AppError.from(error)
            }
        }
    }

    func sendInput(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        sendInput(data)
    }

    private func startOutputListener() {
        outputTask = Task { [weak self] in
            guard let self = self else { return }

            let stream = await session.outputStream

            for await data in stream {
                guard !Task.isCancelled else { break }

                await MainActor.run {
                    // Buffer data if callback not yet set, otherwise deliver immediately
                    if let callback = self.onOutput {
                        callback(data)
                    } else {
                        self.pendingOutputBuffer.append(data)
                    }
                }
            }

            // Stream ended - connection may have been lost
            await MainActor.run {
                if self.isConnected {
                    self.isConnected = false
                    self.state = .error(.terminalConnectionLost)
                }
            }
        }
    }

    // MARK: - Terminal Size

    func resize(columns: Int, rows: Int) {
        // Validate size - must be positive
        guard columns > 0 && rows > 0 else { return }

        currentSize = TerminalSize(columns: columns, rows: rows)

        guard isConnected else { return }

        Task {
            do {
                try await session.resize(columns: columns, rows: rows)
            } catch {
                logError("Failed to resize terminal: \(error)", category: .network)
            }
        }
    }

    // MARK: - Cleanup

    func cleanup() async {
        onOutput = nil
        await disconnect()
    }

    // MARK: - Error Handling

    func clearError() {
        error = nil
        if case .error = state {
            state = .disconnected
        }
    }
}
