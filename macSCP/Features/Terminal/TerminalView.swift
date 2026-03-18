//
//  TerminalView.swift
//  macSCP
//
//  Terminal view with SwiftTerm integration
//

import SwiftUI
import AppKit
import SwiftTerm

// MARK: - Terminal View

struct TerminalContentView: View {
    @Bindable var viewModel: TerminalViewModel

    @State private var showConnectionLostBanner = false
    @State private var showSessionEndedBanner = false

    var body: some View {
        VStack(spacing: 0) {
            // Terminal content
            terminalContent

            Divider()

            // Status bar
            statusBar
        }
        .frame(minWidth: WindowSize.minTerminal.width, minHeight: WindowSize.minTerminal.height)
        .navigationTitle(viewModel.connectionName)
        .navigationSubtitle(navigationSubtitleText)
        .toolbar(id: "terminalToolbar") {
            ToolbarItem(id: "reconnect", placement: .primaryAction) {
                Button {
                    Task {
                        await viewModel.reconnect()
                    }
                } label: {
                    Label("Reconnect", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.state == .connecting)
                .help("Reconnect")
            }


        }
        .task {
            await viewModel.connect()
        }
        .onDisappear {
            Task {
                await viewModel.cleanup()
            }
        }
        .onChange(of: viewModel.state) { oldState, newState in
            // Show banner overlay when connection is lost while terminal was connected
            if case .connected = oldState, case .error = newState {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showConnectionLostBanner = true
                    showSessionEndedBanner = false
                }
            } else if case .connected = oldState, case .disconnected = newState {
                // Graceful session end (e.g. CTRL-D / exit)
                withAnimation(.easeInOut(duration: 0.25)) {
                    showSessionEndedBanner = true
                    showConnectionLostBanner = false
                }
            } else if case .connected = newState {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showConnectionLostBanner = false
                    showSessionEndedBanner = false
                }
            } else if case .connecting = newState {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showConnectionLostBanner = false
                    showSessionEndedBanner = false
                }
            }
        }
        .errorAlert($viewModel.error)
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 5) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)

                Text(statusBarText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Terminal dimensions
            if viewModel.isConnected || showConnectionLostBanner || showSessionEndedBanner {
                Text(viewModel.terminalSizeText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    @ViewBuilder
    private var terminalContent: some View {
        switch viewModel.state {
        case .disconnected:
            if showSessionEndedBanner {
                // Session ended gracefully — preserve terminal content with overlay
                ZStack {
                    SwiftTermView(viewModel: viewModel)
                        .allowsHitTesting(false)
                        .opacity(0.4)

                    sessionEndedBanner
                }
            } else {
                ContentUnavailableView {
                    Label("Disconnected", systemImage: "terminal")
                } description: {
                    Text("The terminal session is not connected.")
                } actions: {
                    Button {
                        Task {
                            await viewModel.reconnect()
                        }
                    } label: {
                        Text("Connect")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }

        case .connecting:
            LoadingView(message: "Connecting...")

        case .connected:
            SwiftTermView(viewModel: viewModel)

        case .error:
            if showConnectionLostBanner {
                // Keep the terminal visible with a reconnect banner overlay
                ZStack {
                    SwiftTermView(viewModel: viewModel)
                        .allowsHitTesting(false)
                        .opacity(0.4)

                    connectionLostBanner
                }
            } else {
                // Initial connection error — no terminal to preserve
                ContentUnavailableView {
                    Label("Connection Failed", systemImage: "wifi.exclamationmark")
                } description: {
                    if case .error(let error) = viewModel.state {
                        Text(error.localizedDescription)
                    }
                } actions: {
                    Button {
                        Task {
                            await viewModel.reconnect()
                        }
                    } label: {
                        Text("Try Again")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
        }
    }

    private var sessionEndedBanner: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Session Ended")
                .font(.system(size: 15, weight: .semibold))

            Text("The remote shell has exited.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    showSessionEndedBanner = false
                    await viewModel.reconnect()
                }
            } label: {
                Label("Reconnect", systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 5)
        }
    }

    private var connectionLostBanner: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Connection Lost")
                .font(.system(size: 15, weight: .semibold))

            if case .error(let error) = viewModel.state {
                Text(error.localizedDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    showConnectionLostBanner = false
                    await viewModel.reconnect()
                }
            } label: {
                Label("Reconnect", systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 5)
        }
    }

    private var statusColor: SwiftUI.Color {
        switch viewModel.state {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return showSessionEndedBanner ? .gray : .red
        case .error:
            return .red
        }
    }

    /// Text shown in the window's navigation subtitle
    private var navigationSubtitleText: String {
        switch viewModel.state {
        case .connected:
            return viewModel.connectionString
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return showSessionEndedBanner ? "Session Ended" : "Disconnected"
        case .error:
            return "Connection Error"
        }
    }

    /// Text shown in the bottom status bar
    private var statusBarText: String {
        switch viewModel.state {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return showSessionEndedBanner ? "Session Ended" : "Disconnected"
        case .error:
            return "Connection Lost"
        }
    }
}

// MARK: - SwiftTerm View (Minimal Wrapper)

struct SwiftTermView: NSViewRepresentable {
    @Bindable var viewModel: TerminalViewModel

    func makeNSView(context: Context) -> TerminalView {
        let terminal = TerminalView()
        terminal.terminalDelegate = context.coordinator
        context.coordinator.terminal = terminal

        // Set up output callback
        viewModel.onOutput = { [weak coordinator = context.coordinator] data in
            DispatchQueue.main.async {
                coordinator?.terminal?.feed(byteArray: ArraySlice([UInt8](data)))
            }
        }

        // Focus after appearing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            terminal.window?.makeFirstResponder(terminal)
        }

        return terminal
    }

    func updateNSView(_ terminal: TerminalView, context: Context) {
        context.coordinator.terminal = terminal
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, TerminalViewDelegate {
        var viewModel: TerminalViewModel
        weak var terminal: TerminalView?

        init(viewModel: TerminalViewModel) {
            self.viewModel = viewModel
        }

        func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
            guard newCols > 0, newRows > 0 else { return }
            viewModel.resize(columns: newCols, rows: newRows)
        }

        func setTerminalTitle(source: TerminalView, title: String) {}

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func send(source: TerminalView, data: ArraySlice<UInt8>) {
            viewModel.sendInput(Data(data))
        }

        func scrolled(source: TerminalView, position: Double) {}

        func clipboardCopy(source: TerminalView, content: Data) {
            if let string = String(data: content, encoding: .utf8) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(string, forType: .string)
            }
        }

        func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}
    }
}

// MARK: - Preview

#Preview {
    TerminalContentView(
        viewModel: TerminalViewModel(
            connectionName: "Test Server",
            session: TerminalSession(),
            connectionData: TerminalWindowData(
                connectionId: UUID(),
                connectionName: "Test",
                host: "localhost",
                port: 2222,
                username: "testuser",
                password: "testpass",
                authMethod: .password,
                privateKeyPath: nil
            )
        )
    )
}
