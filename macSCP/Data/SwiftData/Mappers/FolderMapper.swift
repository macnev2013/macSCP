//
//  FolderMapper.swift
//  macSCP
//
//  Maps between FolderEntity and Folder domain model
//

import Foundation

enum FolderMapper {
    /// Converts a FolderEntity to a Folder domain model
    static func toDomain(_ entity: FolderEntity) -> Folder {
        Folder(
            id: entity.id,
            name: entity.name,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Updates a FolderEntity from a Folder domain model
    static func update(_ entity: FolderEntity, from domain: Folder) {
        entity.name = domain.name
        entity.updatedAt = Date()
    }

    /// Creates a new FolderEntity from a Folder domain model
    static func toEntity(_ domain: Folder) -> FolderEntity {
        FolderEntity(
            id: domain.id,
            name: domain.name,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }
}
