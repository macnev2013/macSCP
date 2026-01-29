//
//  ConnectionMapper.swift
//  macSCP
//
//  Maps between ConnectionEntity and Connection domain model
//

import Foundation

enum ConnectionMapper {
    /// Converts a ConnectionEntity to a Connection domain model
    static func toDomain(_ entity: ConnectionEntity) -> Connection {
        Connection(
            id: entity.id,
            name: entity.name,
            host: entity.host,
            port: entity.port,
            username: entity.username,
            authMethod: AuthMethod(rawValue: entity.authMethod) ?? .password,
            privateKeyPath: entity.privateKeyPath,
            savePassword: entity.savePassword,
            description: entity.connectionDescription,
            tags: entity.tags,
            iconName: entity.iconName,
            folderId: entity.folder?.id,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Updates a ConnectionEntity from a Connection domain model
    static func update(_ entity: ConnectionEntity, from domain: Connection) {
        entity.name = domain.name
        entity.host = domain.host
        entity.port = domain.port
        entity.username = domain.username
        entity.authMethod = domain.authMethod.rawValue
        entity.privateKeyPath = domain.privateKeyPath
        entity.savePassword = domain.savePassword
        entity.connectionDescription = domain.description
        entity.tags = domain.tags
        entity.iconName = domain.iconName
        entity.updatedAt = Date()
    }

    /// Creates a new ConnectionEntity from a Connection domain model
    static func toEntity(_ domain: Connection) -> ConnectionEntity {
        ConnectionEntity(
            id: domain.id,
            name: domain.name,
            host: domain.host,
            port: domain.port,
            username: domain.username,
            authMethod: domain.authMethod.rawValue,
            privateKeyPath: domain.privateKeyPath,
            savePassword: domain.savePassword,
            connectionDescription: domain.description,
            tags: domain.tags,
            iconName: domain.iconName,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }
}
