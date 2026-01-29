//
//  ConnectionRepositoryProtocol.swift
//  macSCP
//
//  Protocol for connection data operations
//

import Foundation

protocol ConnectionRepositoryProtocol: Sendable {
    /// Fetches all connections
    func fetchAll() async throws -> [Connection]

    /// Fetches connections for a specific folder
    func fetchConnections(forFolderId folderId: UUID?) async throws -> [Connection]

    /// Fetches a single connection by ID
    func fetch(id: UUID) async throws -> Connection

    /// Saves a new connection
    func save(_ connection: Connection) async throws

    /// Updates an existing connection
    func update(_ connection: Connection) async throws

    /// Deletes a connection by ID
    func delete(id: UUID) async throws

    /// Moves a connection to a folder
    func move(connectionId: UUID, toFolderId folderId: UUID?) async throws

    /// Searches connections by name
    func search(query: String) async throws -> [Connection]

    /// Returns the count of all connections
    func count() async throws -> Int

    /// Returns the count of connections in a specific folder
    func count(forFolderId folderId: UUID?) async throws -> Int
}
