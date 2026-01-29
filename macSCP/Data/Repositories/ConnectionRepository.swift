//
//  ConnectionRepository.swift
//  macSCP
//
//  Repository implementation for connection operations
//

import Foundation
import SwiftData

final class ConnectionRepository: ConnectionRepositoryProtocol, @unchecked Sendable {
    private let dataStore: DataStore

    init(dataStore: DataStore = .shared) {
        self.dataStore = dataStore
    }

    @MainActor
    func fetchAll() async throws -> [Connection] {
        let context = dataStore.modelContext
        let descriptor = FetchDescriptor<ConnectionEntity>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )

        do {
            let entities = try context.fetch(descriptor)
            return entities.map { ConnectionMapper.toDomain($0) }
        } catch {
            logError("Failed to fetch connections: \(error)", category: .database)
            throw AppError.fetchFailed("connections")
        }
    }

    @MainActor
    func fetchConnections(forFolderId folderId: UUID?) async throws -> [Connection] {
        let context = dataStore.modelContext

        let descriptor: FetchDescriptor<ConnectionEntity>

        if let folderId = folderId {
            descriptor = FetchDescriptor<ConnectionEntity>(
                predicate: #Predicate<ConnectionEntity> { entity in
                    entity.folder?.id == folderId
                },
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
        } else {
            descriptor = FetchDescriptor<ConnectionEntity>(
                predicate: #Predicate<ConnectionEntity> { entity in
                    entity.folder == nil
                },
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
        }

        do {
            let entities = try context.fetch(descriptor)
            return entities.map { ConnectionMapper.toDomain($0) }
        } catch {
            logError("Failed to fetch connections for folder: \(error)", category: .database)
            throw AppError.fetchFailed("connections")
        }
    }

    @MainActor
    func fetch(id: UUID) async throws -> Connection {
        let context = dataStore.modelContext
        let descriptor = FetchDescriptor<ConnectionEntity>(
            predicate: #Predicate<ConnectionEntity> { $0.id == id }
        )

        do {
            guard let entity = try context.fetch(descriptor).first else {
                throw AppError.entityNotFound
            }
            return ConnectionMapper.toDomain(entity)
        } catch let error as AppError {
            throw error
        } catch {
            logError("Failed to fetch connection: \(error)", category: .database)
            throw AppError.fetchFailed("connection")
        }
    }

    @MainActor
    func save(_ connection: Connection) async throws {
        let context = dataStore.modelContext

        let entity = ConnectionMapper.toEntity(connection)

        // Set folder if specified
        if let folderId = connection.folderId {
            let folderDescriptor = FetchDescriptor<FolderEntity>(
                predicate: #Predicate<FolderEntity> { $0.id == folderId }
            )
            if let folder = try? context.fetch(folderDescriptor).first {
                entity.folder = folder
            }
        }

        context.insert(entity)

        do {
            try context.save()
            logInfo("Saved connection: \(connection.name)", category: .database)
        } catch {
            logError("Failed to save connection: \(error)", category: .database)
            throw AppError.saveFailed("connection")
        }
    }

    @MainActor
    func update(_ connection: Connection) async throws {
        let context = dataStore.modelContext
        let descriptor = FetchDescriptor<ConnectionEntity>(
            predicate: #Predicate<ConnectionEntity> { $0.id == connection.id }
        )

        do {
            guard let entity = try context.fetch(descriptor).first else {
                throw AppError.entityNotFound
            }

            ConnectionMapper.update(entity, from: connection)

            // Update folder reference
            if let folderId = connection.folderId {
                let folderDescriptor = FetchDescriptor<FolderEntity>(
                    predicate: #Predicate<FolderEntity> { $0.id == folderId }
                )
                entity.folder = try? context.fetch(folderDescriptor).first
            } else {
                entity.folder = nil
            }

            try context.save()
            logInfo("Updated connection: \(connection.name)", category: .database)
        } catch let error as AppError {
            throw error
        } catch {
            logError("Failed to update connection: \(error)", category: .database)
            throw AppError.saveFailed("connection")
        }
    }

    @MainActor
    func delete(id: UUID) async throws {
        let context = dataStore.modelContext
        let descriptor = FetchDescriptor<ConnectionEntity>(
            predicate: #Predicate<ConnectionEntity> { $0.id == id }
        )

        do {
            guard let entity = try context.fetch(descriptor).first else {
                throw AppError.entityNotFound
            }

            context.delete(entity)
            try context.save()
            logInfo("Deleted connection: \(id)", category: .database)
        } catch let error as AppError {
            throw error
        } catch {
            logError("Failed to delete connection: \(error)", category: .database)
            throw AppError.deleteFailed("connection")
        }
    }

    @MainActor
    func move(connectionId: UUID, toFolderId folderId: UUID?) async throws {
        let context = dataStore.modelContext
        let connectionDescriptor = FetchDescriptor<ConnectionEntity>(
            predicate: #Predicate<ConnectionEntity> { $0.id == connectionId }
        )

        do {
            guard let entity = try context.fetch(connectionDescriptor).first else {
                throw AppError.entityNotFound
            }

            if let folderId = folderId {
                let folderDescriptor = FetchDescriptor<FolderEntity>(
                    predicate: #Predicate<FolderEntity> { $0.id == folderId }
                )
                entity.folder = try? context.fetch(folderDescriptor).first
            } else {
                entity.folder = nil
            }

            entity.updatedAt = Date()
            try context.save()
            logInfo("Moved connection \(connectionId) to folder \(String(describing: folderId))", category: .database)
        } catch let error as AppError {
            throw error
        } catch {
            logError("Failed to move connection: \(error)", category: .database)
            throw AppError.saveFailed("connection")
        }
    }

    @MainActor
    func search(query: String) async throws -> [Connection] {
        let context = dataStore.modelContext
        let lowercaseQuery = query.lowercased()

        let descriptor = FetchDescriptor<ConnectionEntity>(
            predicate: #Predicate<ConnectionEntity> { entity in
                entity.name.localizedStandardContains(lowercaseQuery) ||
                entity.host.localizedStandardContains(lowercaseQuery) ||
                entity.username.localizedStandardContains(lowercaseQuery)
            },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )

        do {
            let entities = try context.fetch(descriptor)
            return entities.map { ConnectionMapper.toDomain($0) }
        } catch {
            logError("Failed to search connections: \(error)", category: .database)
            throw AppError.fetchFailed("connections")
        }
    }

    @MainActor
    func count() async throws -> Int {
        let context = dataStore.modelContext
        let descriptor = FetchDescriptor<ConnectionEntity>()

        do {
            return try context.fetchCount(descriptor)
        } catch {
            logError("Failed to count connections: \(error)", category: .database)
            throw AppError.fetchFailed("connections")
        }
    }

    @MainActor
    func count(forFolderId folderId: UUID?) async throws -> Int {
        let context = dataStore.modelContext

        let descriptor: FetchDescriptor<ConnectionEntity>

        if let folderId = folderId {
            descriptor = FetchDescriptor<ConnectionEntity>(
                predicate: #Predicate<ConnectionEntity> { entity in
                    entity.folder?.id == folderId
                }
            )
        } else {
            descriptor = FetchDescriptor<ConnectionEntity>(
                predicate: #Predicate<ConnectionEntity> { entity in
                    entity.folder == nil
                }
            )
        }

        do {
            return try context.fetchCount(descriptor)
        } catch {
            logError("Failed to count connections for folder: \(error)", category: .database)
            throw AppError.fetchFailed("connections")
        }
    }
}
