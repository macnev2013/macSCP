//
//  DataStore.swift
//  macSCP
//
//  SwiftData ModelContainer setup and management
//

import Foundation
import SwiftData

@MainActor
final class DataStore {
    static let shared = DataStore()

    let modelContainer: ModelContainer

    private init() {
        do {
            let schema = Schema([
                ConnectionEntity.self,
                FolderEntity.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            logInfo("DataStore initialized successfully", category: .database)
        } catch {
            logError("Failed to initialize DataStore: \(error)", category: .database)
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var modelContext: ModelContext {
        modelContainer.mainContext
    }

    /// Creates a new background context for async operations
    func newBackgroundContext() -> ModelContext {
        ModelContext(modelContainer)
    }

    /// Attempts to recover from database corruption by recreating the store
    static func createWithRecovery() -> ModelContainer {
        do {
            return DataStore.shared.modelContainer
        } catch {
            logError("Database recovery failed: \(error)", category: .database)
            fatalError("Cannot recover database: \(error)")
        }
    }
}

// MARK: - Preview Support
extension DataStore {
    @MainActor
    static var preview: DataStore {
        let store = DataStore()
        // Add preview data if needed
        return store
    }
}
