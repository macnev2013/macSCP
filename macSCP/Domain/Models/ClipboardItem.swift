//
//  ClipboardItem.swift
//  macSCP
//
//  Domain model for clipboard operations (copy/cut/paste)
//

import Foundation

enum ClipboardOperation: String, Sendable {
    case copy
    case cut

    var displayName: String {
        switch self {
        case .copy: return "Copy"
        case .cut: return "Cut"
        }
    }

    var pastTense: String {
        switch self {
        case .copy: return "Copied"
        case .cut: return "Cut"
        }
    }

    var iconName: String {
        switch self {
        case .copy: return "doc.on.doc"
        case .cut: return "scissors"
        }
    }
}

struct ClipboardItem: Identifiable, Sendable {
    let id: UUID
    let file: RemoteFile
    let operation: ClipboardOperation
    let sourcePath: String
    let connectionId: UUID

    init(
        id: UUID = UUID(),
        file: RemoteFile,
        operation: ClipboardOperation,
        sourcePath: String,
        connectionId: UUID
    ) {
        self.id = id
        self.file = file
        self.operation = operation
        self.sourcePath = sourcePath
        self.connectionId = connectionId
    }

    var fileName: String {
        file.name
    }

    var isDirectory: Bool {
        file.isDirectory
    }

    var fullSourcePath: String {
        file.path
    }
}

// MARK: - Clipboard State
struct ClipboardState: Sendable {
    var items: [ClipboardItem]
    var operation: ClipboardOperation?

    init(items: [ClipboardItem] = [], operation: ClipboardOperation? = nil) {
        self.items = items
        self.operation = operation
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    var isCopy: Bool {
        operation == .copy
    }

    var isCut: Bool {
        operation == .cut
    }

    var fileCount: Int {
        items.count
    }

    var displayText: String {
        guard !isEmpty, let op = operation else {
            return "Clipboard empty"
        }

        if items.count == 1 {
            return "\(op.pastTense): \(items[0].fileName)"
        }
        return "\(op.pastTense): \(items.count) items"
    }

    var connectionId: UUID? {
        items.first?.connectionId
    }

    mutating func clear() {
        items = []
        operation = nil
    }
}
