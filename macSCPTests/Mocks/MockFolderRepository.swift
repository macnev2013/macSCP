//
//  MockFolderRepository.swift
//  macSCPTests
//
//  Mock implementation of FolderRepositoryProtocol for testing
//

import Foundation
@testable import macSCP

final class MockFolderRepository: FolderRepositoryProtocol, @unchecked Sendable {
    // MARK: - Recorded Calls
    var fetchAllCalled = false
    var fetchCalled = false
    var saveCalled = false
    var updateCalled = false
    var deleteCalled = false
    var existsCalled = false
    var countCalled = false

    // MARK: - Recorded Parameters
    var lastFetchedId: UUID?
    var lastSavedFolder: Folder?
    var lastUpdatedFolder: Folder?
    var lastDeletedId: UUID?
    var lastExistsName: String?

    // MARK: - Mock Responses
    var mockFolders: [Folder] = []
    var mockFolder: Folder?
    var mockError: Error?
    var mockExists: Bool = false
    var mockCount: Int = 0

    // MARK: - Protocol Implementation

    func fetchAll() async throws -> [Folder] {
        fetchAllCalled = true
        if let error = mockError { throw error }
        return mockFolders
    }

    func fetch(id: UUID) async throws -> Folder {
        fetchCalled = true
        lastFetchedId = id
        if let error = mockError { throw error }
        guard let folder = mockFolder ?? mockFolders.first(where: { $0.id == id }) else {
            throw AppError.entityNotFound
        }
        return folder
    }

    func save(_ folder: Folder) async throws {
        saveCalled = true
        lastSavedFolder = folder
        if let error = mockError { throw error }
        mockFolders.append(folder)
    }

    func update(_ folder: Folder) async throws {
        updateCalled = true
        lastUpdatedFolder = folder
        if let error = mockError { throw error }
        if let index = mockFolders.firstIndex(where: { $0.id == folder.id }) {
            mockFolders[index] = folder
        }
    }

    func delete(id: UUID) async throws {
        deleteCalled = true
        lastDeletedId = id
        if let error = mockError { throw error }
        mockFolders.removeAll { $0.id == id }
    }

    func exists(name: String) async throws -> Bool {
        existsCalled = true
        lastExistsName = name
        if let error = mockError { throw error }
        return mockExists || mockFolders.contains { $0.name == name }
    }

    func count() async throws -> Int {
        countCalled = true
        if let error = mockError { throw error }
        return mockCount > 0 ? mockCount : mockFolders.count
    }

    // MARK: - Reset
    func reset() {
        fetchAllCalled = false
        fetchCalled = false
        saveCalled = false
        updateCalled = false
        deleteCalled = false
        existsCalled = false
        countCalled = false

        lastFetchedId = nil
        lastSavedFolder = nil
        lastUpdatedFolder = nil
        lastDeletedId = nil
        lastExistsName = nil

        mockFolders = []
        mockFolder = nil
        mockError = nil
        mockExists = false
        mockCount = 0
    }
}
