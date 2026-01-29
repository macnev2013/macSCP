//
//  FolderEntity.swift
//  macSCP
//
//  SwiftData entity for connection folders
//

import Foundation
import SwiftData

@Model
final class FolderEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \ConnectionEntity.folder)
    var connections: [ConnectionEntity]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.connections = []
    }
}
