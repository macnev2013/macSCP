//
//  FolderRepositoryProtocol.swift
//  macSCP
//
//  Protocol for folder data operations
//

import Foundation

protocol FolderRepositoryProtocol: Sendable {
    /// Fetches all folders
    func fetchAll() async throws -> [Folder]

    /// Fetches a single folder by ID
    func fetch(id: UUID) async throws -> Folder

    /// Saves a new folder
    func save(_ folder: Folder) async throws

    /// Updates an existing folder
    func update(_ folder: Folder) async throws

    /// Deletes a folder by ID (connections in the folder become uncategorized)
    func delete(id: UUID) async throws

    /// Returns true if a folder with the given name exists
    func exists(name: String) async throws -> Bool

    /// Returns the count of all folders
    func count() async throws -> Int
}
