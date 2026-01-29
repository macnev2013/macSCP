//
//  MockClipboardService.swift
//  macSCPTests
//
//  Mock implementation of ClipboardService for testing
//

import Foundation
@testable import macSCP

@MainActor
final class MockClipboardService {
    // MARK: - State
    private(set) var state = ClipboardState()

    // MARK: - Recorded Calls
    var copyCalled = false
    var cutCalled = false
    var clearCalled = false

    // MARK: - Recorded Parameters
    var lastCopiedFiles: [RemoteFile]?
    var lastCopiedSourcePath: String?
    var lastCopiedConnectionId: UUID?
    var lastCutFiles: [RemoteFile]?
    var lastCutSourcePath: String?
    var lastCutConnectionId: UUID?

    // MARK: - Methods

    func copy(files: [RemoteFile], from sourcePath: String, connectionId: UUID) {
        copyCalled = true
        lastCopiedFiles = files
        lastCopiedSourcePath = sourcePath
        lastCopiedConnectionId = connectionId

        let items = files.map { file in
            ClipboardItem(
                file: file,
                operation: .copy,
                sourcePath: sourcePath,
                connectionId: connectionId
            )
        }
        state = ClipboardState(items: items, operation: .copy)
    }

    func cut(files: [RemoteFile], from sourcePath: String, connectionId: UUID) {
        cutCalled = true
        lastCutFiles = files
        lastCutSourcePath = sourcePath
        lastCutConnectionId = connectionId

        let items = files.map { file in
            ClipboardItem(
                file: file,
                operation: .cut,
                sourcePath: sourcePath,
                connectionId: connectionId
            )
        }
        state = ClipboardState(items: items, operation: .cut)
    }

    func clear() {
        clearCalled = true
        state.clear()
    }

    // MARK: - Computed Properties

    var isEmpty: Bool { state.isEmpty }
    var isCopy: Bool { state.isCopy }
    var isCut: Bool { state.isCut }
    var items: [ClipboardItem] { state.items }
    var fileCount: Int { state.fileCount }
    var displayText: String { state.displayText }
    var connectionId: UUID? { state.connectionId }

    func canPaste(to connectionId: UUID) -> Bool {
        guard !isEmpty else { return false }
        return state.connectionId == connectionId
    }

    // MARK: - Reset
    func reset() {
        state = ClipboardState()
        copyCalled = false
        cutCalled = false
        clearCalled = false
        lastCopiedFiles = nil
        lastCopiedSourcePath = nil
        lastCopiedConnectionId = nil
        lastCutFiles = nil
        lastCutSourcePath = nil
        lastCutConnectionId = nil
    }
}
