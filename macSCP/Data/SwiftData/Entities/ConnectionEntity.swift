//
//  ConnectionEntity.swift
//  macSCP
//
//  SwiftData entity for SSH connections
//

import Foundation
import SwiftData

@Model
final class ConnectionEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var authMethod: String
    var privateKeyPath: String?
    var savePassword: Bool
    var connectionDescription: String?
    var tags: [String]
    var iconName: String
    var createdAt: Date
    var updatedAt: Date

    var folder: FolderEntity?

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        authMethod: String = "password",
        privateKeyPath: String? = nil,
        savePassword: Bool = false,
        connectionDescription: String? = nil,
        tags: [String] = [],
        iconName: String = "server.rack",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.privateKeyPath = privateKeyPath
        self.savePassword = savePassword
        self.connectionDescription = connectionDescription
        self.tags = tags
        self.iconName = iconName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
