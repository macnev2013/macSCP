//
//  FolderRepository.swift
//  macSCP
//
//  Repository implementation for folder operations
//

import Foundation
import SwiftData

final class FolderRepository: FolderRepositoryProtocol, @unchecked Sendable {
    private let dataStore: DataStore

    init(dataStore: DataStore = .shared) {
        self.dataStore = dataStore
    }

    @MainActor
    func fetchAll() async throws -> [Folder] {
        let context = dataStore.modelContext
        let descriptor = FetchDescriptor<FolderEntity>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )

        do {
            let entities = try context.fetch(descriptor)
            return entities.map { FolderMapper.toDomain($0) }
        } catch {
            logError("Failed to fetch folders: \(error)", category: .database)
            throw AppError.fetchFailed("folders")
        }
    }

    @MainActor
    func fetch(id: UUID) async throws -> Folder {
        let context = dataStore.modelContext
        let descriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate<FolderEntity> { $0.id == id }
        )

        do {
            guard let entity = try context.fetch(descriptor).first else {
                throw AppError.entityNotFound
            }
            return FolderMapper.toDomain(entity)
        } catch let error as AppError {
            throw error
        } catch {
            logError("Failed to fetch folder: \(error)", category: .database)
            throw AppError.fetchFailed("folder")
        }
    }

    @MainActor
    func save(_ folder: Folder) async throws {
        let context = dataStore.modelContext
        let entity = FolderMapper.toEntity(folder)

        context.insert(entity)

        do {
            try context.save()
            logInfo("Saved folder: \(folder.name)", category: .database)
        } catch {
            logError("Failed to save folder: \(error)", category: .database)
            throw AppError.saveFailed("folder")
        }
    }

    @MainActor
    func update(_ folder: Folder) async throws {
        let context = dataStore.modelContext
        let descriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate<FolderEntity> { $0.id == folder.id }
        )

        do {
            guard let entity = try context.fetch(descriptor).first else {
                throw AppError.entityNotFound
            }

            FolderMapper.update(entity, from: folder)
            try context.save()
            logInfo("Updated folder: \(folder.name)", category: .database)
        } catch let error as AppError {
            throw error
        } catch {
            logError("Failed to update folder: \(error)", category: .database)
            throw AppError.saveFailed("folder")
        }
    }

    @MainActor
    func delete(id: UUID) async throws {
        let context = dataStore.modelContext
        let descriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate<FolderEntity> { $0.id == id }
        )

        do {
            guard let entity = try context.fetch(descriptor).first else {
                throw AppError.entityNotFound
            }

            // Connections in this folder will have their folder set to nil due to nullify delete rule
            context.delete(entity)
            try context.save()
            logInfo("Deleted folder: \(id)", category: .database)
        } catch let error as AppError {
            throw error
        } catch {
            logError("Failed to delete folder: \(error)", category: .database)
            throw AppError.deleteFailed("folder")
        }
    }

    @MainActor
    func exists(name: String) async throws -> Bool {
        let context = dataStore.modelContext
        let descriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate<FolderEntity> { $0.name == name }
        )

        do {
            let count = try context.fetchCount(descriptor)
            return count > 0
        } catch {
            logError("Failed to check folder existence: \(error)", category: .database)
            throw AppError.fetchFailed("folder")
        }
    }

    @MainActor
    func count() async throws -> Int {
        let context = dataStore.modelContext
        let descriptor = FetchDescriptor<FolderEntity>()

        do {
            return try context.fetchCount(descriptor)
        } catch {
            logError("Failed to count folders: \(error)", category: .database)
            throw AppError.fetchFailed("folders")
        }
    }
}
