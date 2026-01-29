//
//  EditorStatusBar.swift
//  macSCP
//
//  Status bar for the file editor
//

import SwiftUI

struct EditorStatusBar: View {
    @Bindable var viewModel: FileEditorViewModel

    var body: some View {
        HStack {
            // File path
            Text(viewModel.filePath)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // Statistics
            HStack(spacing: UIConstants.spacing) {
                StatItem(label: "Lines", value: "\(viewModel.lineCount)")
                StatItem(label: "Words", value: "\(viewModel.wordCount)")
                StatItem(label: "Characters", value: "\(viewModel.characterCount)")
            }

            // Save status
            if viewModel.state.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if viewModel.hasChanges {
                Text("Modified")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("Saved")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Stat Item
private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    EditorStatusBar(viewModel: FileEditorViewModel(
        filePath: "/home/user/documents/test.txt",
        fileName: "test.txt",
        initialContent: "Hello, World!",
        fileRepository: FileRepository(sftpSession: SFTPSession())
    ))
}
