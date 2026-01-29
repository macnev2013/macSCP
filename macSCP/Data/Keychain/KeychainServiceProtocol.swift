//
//  KeychainServiceProtocol.swift
//  macSCP
//
//  Protocol for keychain operations
//

import Foundation

protocol KeychainServiceProtocol: Sendable {
    /// Saves a password for a connection
    func savePassword(_ password: String, for connectionId: UUID) throws

    /// Retrieves a password for a connection
    func getPassword(for connectionId: UUID) -> String?

    /// Deletes a password for a connection
    func deletePassword(for connectionId: UUID) throws

    /// Updates a password for a connection
    func updatePassword(_ password: String, for connectionId: UUID) throws

    /// Checks if a password exists for a connection
    func hasPassword(for connectionId: UUID) -> Bool
}
