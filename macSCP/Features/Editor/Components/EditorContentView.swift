//
//  EditorContentView.swift
//  macSCP
//
//  Text editor content view
//

import SwiftUI

struct EditorContentView: View {
    @Bindable var viewModel: FileEditorViewModel

    var body: some View {
        TextEditor(text: $viewModel.content)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .background(Color(.textBackgroundColor))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview {
    EditorContentView(viewModel: FileEditorViewModel(
        filePath: "/test.txt",
        fileName: "test.txt",
        initialContent: """
        function hello() {
            console.log("Hello, World!");
        }

        hello();
        """,
        fileRepository: FileRepository(sftpSession: SFTPSession())
    ))
}
