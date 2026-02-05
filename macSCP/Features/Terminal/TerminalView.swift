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

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            terminalToolbar

            Divider()

            // Terminal content
            terminalContent
        }
        .frame(minWidth: WindowSize.minTerminal.width, minHeight: WindowSize.minTerminal.height)
        .task {
            await viewModel.connect()
        }
        .onDisappear {
            Task {
                await viewModel.cleanup()
            }
        }
        .errorAlert($viewModel.error)
    }

    @ViewBuilder
    private var terminalToolbar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await viewModel.reconnect()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.state == .connecting)
            .help("Reconnect")

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var terminalContent: some View {
        switch viewModel.state {
        case .disconnected:
            ContentUnavailableView(
                "Disconnected",
                systemImage: "terminal",
                description: Text("Click Reconnect to establish a connection")
            )

        case .connecting:
            LoadingView(message: "Connecting...")

        case .connected:
            SwiftTermView(viewModel: viewModel)

        case .error(let error):
            ErrorView(error: error) {
                Task {
                    await viewModel.reconnect()
                }
            }
        }
    }

    private var statusColor: SwiftUI.Color {
        switch viewModel.state {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected, .error:
            return .red
        }
    }

    private var statusText: String {
        switch viewModel.state {
        case .connected:
            return viewModel.connectionName
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Connection Error"
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
