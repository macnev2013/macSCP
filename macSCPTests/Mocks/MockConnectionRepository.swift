//
//  MockConnectionRepository.swift
//  macSCPTests
//
//  Mock implementation of ConnectionRepositoryProtocol for testing
//

import Foundation
@testable import macSCP

final class MockConnectionRepository: ConnectionRepositoryProtocol, @unchecked Sendable {
    // MARK: - Recorded Calls
    var fetchAllCalled = false
    var fetchConnectionsForFolderIdCalled = false
    var fetchCalled = false
    var saveCalled = false
    var updateCalled = false
    var deleteCalled = false
    var moveCalled = false
    var searchCalled = false
    var countCalled = false

    // MARK: - Recorded Parameters
    var lastFetchedFolderId: UUID?
    var lastFetchedId: UUID?
    var lastSavedConnection: Connection?
    var lastUpdatedConnection: Connection?
    var lastDeletedId: UUID?
    var lastMoveConnectionId: UUID?
    var lastMoveFolderId: UUID?
    var lastSearchQuery: String?

    // MARK: - Mock Responses
    var mockConnections: [Connection] = []
    var mockConnection: Connection?
    var mockError: Error?
    var mockCount: Int = 0

    // MARK: - Protocol Implementation

    func fetchAll() async throws -> [Connection] {
        fetchAllCalled = true
        if let error = mockError { throw error }
        return mockConnections
    }

    func fetchConnections(forFolderId folderId: UUID?) async throws -> [Connection] {
        fetchConnectionsForFolderIdCalled = true
        lastFetchedFolderId = folderId
        if let error = mockError { throw error }
        return mockConnections.filter { $0.folderId == folderId }
    }

    func fetch(id: UUID) async throws -> Connection {
        fetchCalled = true
        lastFetchedId = id
        if let error = mockError { throw error }
        guard let connection = mockConnection ?? mockConnections.first(where: { $0.id == id }) else {
            throw AppError.entityNotFound
        }
        return connection
    }

    func save(_ connection: Connection) async throws {
        saveCalled = true
        lastSavedConnection = connection
        if let error = mockError { throw error }
        mockConnections.append(connection)
    }

    func update(_ connection: Connection) async throws {
        updateCalled = true
        lastUpdatedConnection = connection
        if let error = mockError { throw error }
        if let index = mockConnections.firstIndex(where: { $0.id == connection.id }) {
            mockConnections[index] = connection
        }
    }

    func delete(id: UUID) async throws {
        deleteCalled = true
        lastDeletedId = id
        if let error = mockError { throw error }
        mockConnections.removeAll { $0.id == id }
    }

    func move(connectionId: UUID, toFolderId folderId: UUID?) async throws {
        moveCalled = true
        lastMoveConnectionId = connectionId
        lastMoveFolderId = folderId
        if let error = mockError { throw error }
    }

    func search(query: String) async throws -> [Connection] {
        searchCalled = true
        lastSearchQuery = query
        if let error = mockError { throw error }
        return mockConnections.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.host.localizedCaseInsensitiveContains(query)
        }
    }

    func count() async throws -> Int {
        countCalled = true
        if let error = mockError { throw error }
        return mockCount > 0 ? mockCount : mockConnections.count
    }

    func count(forFolderId folderId: UUID?) async throws -> Int {
        countCalled = true
        if let error = mockError { throw error }
        return mockConnections.filter { $0.folderId == folderId }.count
    }

    // MARK: - Reset
    func reset() {
        fetchAllCalled = false
        fetchConnectionsForFolderIdCalled = false
        fetchCalled = false
        saveCalled = false
        updateCalled = false
        deleteCalled = false
        moveCalled = false
        searchCalled = false
        countCalled = false

        lastFetchedFolderId = nil
        lastFetchedId = nil
        lastSavedConnection = nil
        lastUpdatedConnection = nil
        lastDeletedId = nil
        lastMoveConnectionId = nil
        lastMoveFolderId = nil
        lastSearchQuery = nil

        mockConnections = []
        mockConnection = nil
        mockError = nil
        mockCount = 0
    }
}
