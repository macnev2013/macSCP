//
//  TerminalWindow.swift
//  macSCP
//
//  Window wrapper for the terminal
//

import SwiftUI

struct TerminalWindow: View {
    let windowId: String
    @State private var viewModel: TerminalViewModel?
    @State private var showMissingDataError = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if showMissingDataError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("Session Expired")
                        .font(.headline)
                    Text("This window's session data was lost. Please reconnect from the main window.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Close Window") {
                        dismiss()
                    }
                }
                .padding(32)
            } else if let viewModel = viewModel {
                TerminalContentView(viewModel: viewModel)
                    .navigationTitle("\(viewModel.connectionName) - Terminal")
            } else {
                LoadingView(message: "Initializing...")
                    .task {
                        initializeViewModel()
                    }
            }
        }
        .frame(minWidth: WindowSize.minTerminal.width, minHeight: WindowSize.minTerminal.height)
    }

    @MainActor
    private func initializeViewModel() {
        let windowManager = WindowManager.shared

        guard let data = windowManager.getTerminalData(for: windowId) else {
            logError("No terminal window data found for ID: \(windowId)", category: .ui)
            showMissingDataError = true
            return
        }

        let container = DependencyContainer.shared
        let session = container.makeTerminalSession()

        viewModel = container.makeTerminalViewModel(
            connectionName: data.connectionName,
            session: session,
            connectionData: data
        )
    }
}

// MARK: - Preview

#Preview {
    TerminalWindow(windowId: "preview")
}
