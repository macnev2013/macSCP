//
//  MockKeychainService.swift
//  macSCPTests
//
//  Mock implementation of KeychainServiceProtocol for testing
//

import Foundation
@testable import macSCP

final class MockKeychainService: KeychainServiceProtocol, @unchecked Sendable {
    // MARK: - Recorded Calls
    var savePasswordCalled = false
    var getPasswordCalled = false
    var deletePasswordCalled = false
    var updatePasswordCalled = false
    var hasPasswordCalled = false

    // MARK: - Recorded Parameters
    var lastSavedPassword: String?
    var lastSavedConnectionId: UUID?
    var lastGetConnectionId: UUID?
    var lastDeleteConnectionId: UUID?
    var lastUpdatePassword: String?
    var lastUpdateConnectionId: UUID?
    var lastHasPasswordConnectionId: UUID?

    // MARK: - Mock Responses
    var mockPasswords: [UUID: String] = [:]
    var mockError: Error?

    // MARK: - Protocol Implementation

    func savePassword(_ password: String, for connectionId: UUID) throws {
        savePasswordCalled = true
        lastSavedPassword = password
        lastSavedConnectionId = connectionId
        if let error = mockError { throw error }
        mockPasswords[connectionId] = password
    }

    func getPassword(for connectionId: UUID) -> String? {
        getPasswordCalled = true
        lastGetConnectionId = connectionId
        return mockPasswords[connectionId]
    }

    func deletePassword(for connectionId: UUID) throws {
        deletePasswordCalled = true
        lastDeleteConnectionId = connectionId
        if let error = mockError { throw error }
        mockPasswords.removeValue(forKey: connectionId)
    }

    func updatePassword(_ password: String, for connectionId: UUID) throws {
        updatePasswordCalled = true
        lastUpdatePassword = password
        lastUpdateConnectionId = connectionId
        if let error = mockError { throw error }
        mockPasswords[connectionId] = password
    }

    func hasPassword(for connectionId: UUID) -> Bool {
        hasPasswordCalled = true
        lastHasPasswordConnectionId = connectionId
        return mockPasswords[connectionId] != nil
    }

    // MARK: - Reset
    func reset() {
        savePasswordCalled = false
        getPasswordCalled = false
        deletePasswordCalled = false
        updatePasswordCalled = false
        hasPasswordCalled = false

        lastSavedPassword = nil
        lastSavedConnectionId = nil
        lastGetConnectionId = nil
        lastDeleteConnectionId = nil
        lastUpdatePassword = nil
        lastUpdateConnectionId = nil
        lastHasPasswordConnectionId = nil

        mockPasswords = [:]
        mockError = nil
    }
}
