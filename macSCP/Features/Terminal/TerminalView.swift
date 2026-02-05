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
            // Connection status with reconnect icon
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            // Reconnect icon button
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
            SwiftTermWrapper(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

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

// MARK: - SwiftTerm Wrapper

struct SwiftTermWrapper: NSViewRepresentable {
    @Bindable var viewModel: TerminalViewModel

    func makeNSView(context: Context) -> NSView {
        // Create container view with padding
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0).cgColor

        // Create terminal view
        let terminal = SwiftTerm.TerminalView(frame: containerView.bounds)
        terminal.terminalDelegate = context.coordinator
        terminal.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        terminal.translatesAutoresizingMaskIntoConstraints = false

        // Configure terminal appearance - dark theme
        terminal.nativeForegroundColor = .white
        terminal.nativeBackgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)

        // Add terminal to container with padding constraints
        let padding: CGFloat = 8
        containerView.addSubview(terminal)
        NSLayoutConstraint.activate([
            terminal.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            terminal.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding),
            terminal.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding),
            terminal.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding)
        ])

        // Set up output callback from ViewModel
        context.coordinator.terminal = terminal
        viewModel.onOutput = { [weak coordinator = context.coordinator] data in
            DispatchQueue.main.async {
                coordinator?.receiveOutput(data)
            }
        }

        // Request focus for keyboard input after view is added to window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let window = terminal.window {
                window.makeFirstResponder(terminal)
            }
        }

        return containerView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Find the terminal view inside the container
        guard let terminal = nsView.subviews.first as? SwiftTerm.TerminalView else { return }

        // Ensure coordinator has reference to terminal
        context.coordinator.terminal = terminal

        // Ensure terminal has keyboard focus when view updates
        if let window = terminal.window, window.firstResponder != terminal {
            window.makeFirstResponder(terminal)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, SwiftTerm.TerminalViewDelegate {
        var viewModel: TerminalViewModel
        weak var terminal: SwiftTerm.TerminalView?

        init(viewModel: TerminalViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - TerminalViewDelegate

        func sizeChanged(source: SwiftTerm.TerminalView, newCols: Int, newRows: Int) {
            // Only send valid terminal sizes
            guard newCols > 0 && newRows > 0 else { return }
            viewModel.resize(columns: newCols, rows: newRows)
        }

        func setTerminalTitle(source: SwiftTerm.TerminalView, title: String) {
            // Title changes can be ignored or used for window title
        }

        func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {
            // Directory updates from the shell
        }

        func send(source: SwiftTerm.TerminalView, data: ArraySlice<UInt8>) {
            viewModel.sendInput(Data(data))
        }

        func scrolled(source: SwiftTerm.TerminalView, position: Double) {
            // Scroll position changed
        }

        func clipboardCopy(source: SwiftTerm.TerminalView, content: Data) {
            if let string = String(data: content, encoding: .utf8) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(string, forType: .string)
            }
        }

        func rangeChanged(source: SwiftTerm.TerminalView, startY: Int, endY: Int) {
            // Range changed - used for selection
        }

        // MARK: - Output Handling

        func receiveOutput(_ data: Data) {
            guard let terminal = terminal else { return }
            terminal.feed(byteArray: ArraySlice([UInt8](data)))
            terminal.setNeedsDisplay(terminal.bounds)
        }
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
                port: 22,
                username: "user",
                password: "password",
                authMethod: .password,
                privateKeyPath: nil
            )
        )
    )
}
