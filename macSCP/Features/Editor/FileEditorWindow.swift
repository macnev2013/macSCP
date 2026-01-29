//
//  FileEditorWindow.swift
//  macSCP
//
//  Window wrapper for the file editor
//

import SwiftUI

struct FileEditorWindow: View {
    let windowId: String
    @State private var viewModel: FileEditorViewModel?
    @State private var isConnecting = true
    @State private var connectionError: AppError?
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
                    Text("This editor's session data was lost. Please reopen the file from the browser.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Close Window") {
                        dismiss()
                    }
                }
                .padding(32)
            } else if let viewModel = viewModel {
                FileEditorView(viewModel: viewModel)
                    .navigationTitle(viewModel.fileName)
            } else if let error = connectionError {
                ErrorView(error: error) {
                    Task {
                        await initializeViewModel()
                    }
                }
            } else {
                LoadingView(message: "Connecting...")
                    .task {
                        await initializeViewModel()
                    }
            }
        }
        .frame(minWidth: WindowSize.fileEditor.width, minHeight: WindowSize.fileEditor.height)
    }

    @MainActor
    private func initializeViewModel() async {
        let windowManager = WindowManager.shared

        guard let data = windowManager.getFileEditorData(for: windowId) else {
            logError("No editor data found for ID: \(windowId)", category: .ui)
            showMissingDataError = true
            return
        }

        let container = DependencyContainer.shared
        let sftpSession = container.makeSFTPSession()

        // Connect the session before creating the file repository
        do {
            switch data.authMethod {
            case .password:
                try await sftpSession.connect(
                    host: data.host,
                    port: data.port,
                    username: data.username,
                    password: data.password
                )
            case .privateKey:
                try await sftpSession.connect(
                    host: data.host,
                    port: data.port,
                    username: data.username,
                    privateKeyPath: data.privateKeyPath ?? "",
                    passphrase: data.password.isEmpty ? nil : data.password
                )
            }

            let fileRepository = container.makeFileRepository(session: sftpSession)

            viewModel = FileEditorViewModel(
                filePath: data.filePath,
                fileName: data.fileName,
                initialContent: data.content,
                fileRepository: fileRepository
            )
        } catch {
            logError("Failed to connect for editor: \(error)", category: .sftp)
            connectionError = AppError.from(error)
        }
    }
}

// MARK: - Preview
#Preview {
    FileEditorWindow(windowId: "preview")
}
