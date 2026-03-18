//
//  TerminalSession.swift
//  macSCP
//
//  Actor-based terminal session using Citadel SSH with PTY
//

import Foundation
import Citadel
import NIO
import NIOCore
import NIOFoundationCompat
import NIOSSH

actor TerminalSession: TerminalSessionProtocol {
    private var client: SSHClient?
    private var eventLoopGroup: MultiThreadedEventLoopGroup?
    private(set) var isConnected = false
    private(set) var sessionEndedGracefully = false

    // PTY state
    private var ptyTask: Task<Void, Error>?
    private var ttyWriter: TTYStdinWriter?
    private var outputContinuation: AsyncStream<Data>.Continuation?
    private var currentSize: TerminalSize = .default

    // Output stream for terminal data
    private var _outputStream: AsyncStream<Data>?
    var outputStream: AsyncStream<Data> {
        get async {
            if let stream = _outputStream {
                return stream
            }
            let (stream, continuation) = AsyncStream<Data>.makeStream()
            outputContinuation = continuation
            _outputStream = stream
            return stream
        }
    }

    init() {}

    // MARK: - Connection with Password

    func connect(
        host: String,
        port: Int,
        username: String,
        password: String,
        terminalSize: TerminalSize
    ) async throws {
        logInfo("Connecting terminal to \(username)@\(host):\(port) with password", category: .network)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        eventLoopGroup = group
        currentSize = terminalSize
        sessionEndedGracefully = false

        do {
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

            // Initialize output stream if not already
            _ = await outputStream

            // Start PTY session
            try await startPTYSession()

            logInfo("Terminal connected successfully to \(host)", category: .network)
        } catch {
            try? await group.shutdownGracefully()
            eventLoopGroup = nil
            throw parseConnectionError(error)
        }
    }

    // MARK: - Connection with Private Key

    func connect(
        host: String,
        port: Int,
        username: String,
        privateKeyPath: String,
        passphrase: String?,
        terminalSize: TerminalSize
    ) async throws {
        logInfo("Connecting terminal to \(username)@\(host):\(port) with private key", category: .network)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        eventLoopGroup = group
        currentSize = terminalSize
        sessionEndedGracefully = false

        do {
            let normalizedHost = (host.lowercased() == "localhost") ? "127.0.0.1" : host

            let privateKeyURL = URL(fileURLWithPath: privateKeyPath)
            let privateKeyData = try Data(contentsOf: privateKeyURL)
            guard let privateKeyString = String(data: privateKeyData, encoding: .utf8) else {
                throw AppError.authenticationFailed
            }

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

            // Initialize output stream if not already
            _ = await outputStream

            // Start PTY session
            try await startPTYSession()

            logInfo("Terminal connected successfully to \(host)", category: .network)
        } catch {
            try? await group.shutdownGracefully()
            eventLoopGroup = nil
            throw parseConnectionError(error)
        }
    }

    // MARK: - PTY Session

    private func startPTYSession() async throws {
        guard let client = client else {
            throw AppError.notConnected
        }

        // Capture current size before entering task
        let cols = currentSize.columns
        let rows = currentSize.rows

        // Create a task to run the PTY session
        ptyTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                // Create terminal modes with ECHO enabled
                let terminalModes = SSHTerminalModes([
                    .ECHO: 1,      // Enable echo
                    .ICANON: 1,    // Enable canonical mode
                    .ISIG: 1,      // Enable signals
                    .ICRNL: 1,     // Map CR to NL on input
                    .ONLCR: 1,     // Map NL to CR-NL on output
                    .OPOST: 1      // Enable output processing
                ])

                // Create PTY request with proper terminal modes
                let ptyRequest = SSHChannelRequestEvent.PseudoTerminalRequest(
                    wantReply: true,
                    term: "xterm-256color",
                    terminalCharacterWidth: cols,
                    terminalRowHeight: rows,
                    terminalPixelWidth: 0,
                    terminalPixelHeight: 0,
                    terminalModes: terminalModes
                )

                // Open a shell channel with PTY using Citadel's withPTY
                try await client.withPTY(ptyRequest) { ttyOutput, ttyWriter in
                    // Store the writer for sending input and resize
                    await self.setTTYWriter(ttyWriter)

                    // Read output from the TTY and forward to the stream
                    for try await output in ttyOutput {
                        // Check for task cancellation
                        if Task.isCancelled { break }

                        switch output {
                        case .stdout(let buffer):
                            let data = Data(buffer: buffer)
                            await self.sendOutput(data)
                        case .stderr(let buffer):
                            let data = Data(buffer: buffer)
                            await self.sendOutput(data)
                        }
                    }
                }

                // PTY stream ended normally (e.g. user exited shell with CTRL-D/exit)
                if !Task.isCancelled {
                    logInfo("Terminal session ended gracefully", category: .network)
                    await self.handleGracefulSessionEnd()
                }
            } catch {
                // Only log as error if not cancelled (intentional disconnect)
                if !Task.isCancelled {
                    logError("PTY session error: \(error)", category: .network)
                    await self.handlePTYError(error)
                }
            }
        }
    }

    private func setTTYWriter(_ writer: TTYStdinWriter) {
        ttyWriter = writer
    }

    private func sendOutput(_ data: Data) {
        outputContinuation?.yield(data)
    }

    private func handleGracefulSessionEnd() {
        isConnected = false
        sessionEndedGracefully = true
        outputContinuation?.finish()
    }

    private func handlePTYError(_ error: Error) {
        isConnected = false
        outputContinuation?.finish()
    }

    // MARK: - Send Data

    func send(_ data: Data) async throws {
        guard isConnected else {
            throw AppError.notConnected
        }

        guard let writer = ttyWriter else {
            throw AppError.terminalPTYFailed
        }

        try await writer.write(ByteBuffer(data: data))
    }

    // MARK: - Resize

    func resize(columns: Int, rows: Int) async throws {
        guard isConnected else { return }

        currentSize = TerminalSize(columns: columns, rows: rows)

        guard let writer = ttyWriter else { return }

        do {
            try await writer.changeSize(cols: columns, rows: rows, pixelWidth: 0, pixelHeight: 0)
        } catch {
            logError("Failed to resize terminal: \(error)", category: .network)
        }
    }

    // MARK: - Disconnect

    func disconnect() async {
        logInfo("Disconnecting terminal", category: .network)

        ptyTask?.cancel()
        ptyTask = nil
        ttyWriter = nil

        outputContinuation?.finish()
        outputContinuation = nil
        _outputStream = nil

        try? await client?.close()
        try? await eventLoopGroup?.shutdownGracefully()

        client = nil
        eventLoopGroup = nil
        isConnected = false
    }

    // MARK: - Error Parsing

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

        return .terminalConnectionFailed(error.localizedDescription)
    }
}
