//
//  ClipboardService.swift
//  macSCP
//
//  Service for managing remote file clipboard operations
//

import Foundation

@MainActor
@Observable
final class ClipboardService {
    static let shared = ClipboardService()

    private(set) var state = ClipboardState()

    private init() {}

    // MARK: - Public Methods

    /// Copies files to the clipboard
    func copy(files: [RemoteFile], from sourcePath: String, connectionId: UUID) {
        let items = files.map { file in
            ClipboardItem(
                file: file,
                operation: .copy,
                sourcePath: sourcePath,
                connectionId: connectionId
            )
        }

        state = ClipboardState(items: items, operation: .copy)
        logDebug("Copied \(files.count) items to clipboard", category: .app)
    }

    /// Cuts files to the clipboard
    func cut(files: [RemoteFile], from sourcePath: String, connectionId: UUID) {
        let items = files.map { file in
            ClipboardItem(
                file: file,
                operation: .cut,
                sourcePath: sourcePath,
                connectionId: connectionId
            )
        }

        state = ClipboardState(items: items, operation: .cut)
        logDebug("Cut \(files.count) items to clipboard", category: .app)
    }

    /// Clears the clipboard
    func clear() {
        state.clear()
        logDebug("Clipboard cleared", category: .app)
    }

    // MARK: - Computed Properties

    var isEmpty: Bool {
        state.isEmpty
    }

    var isCopy: Bool {
        state.isCopy
    }

    var isCut: Bool {
        state.isCut
    }

    var items: [ClipboardItem] {
        state.items
    }

    var fileCount: Int {
        state.fileCount
    }

    var displayText: String {
        state.displayText
    }

    var connectionId: UUID? {
        state.connectionId
    }

    /// Returns true if the clipboard can paste to the given connection
    func canPaste(to connectionId: UUID) -> Bool {
        guard !isEmpty else { return false }
        return state.connectionId == connectionId
    }
}
