//
//  Connection.swift
//  macSCP
//
//  Domain model for SSH connections
//

import Foundation

struct Connection: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var authMethod: AuthMethod
    var privateKeyPath: String?
    var savePassword: Bool
    var description: String?
    var tags: [String]
    var iconName: String
    var folderId: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        authMethod: AuthMethod = .password,
        privateKeyPath: String? = nil,
        savePassword: Bool = false,
        description: String? = nil,
        tags: [String] = [],
        iconName: String = "server.rack",
        folderId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.privateKeyPath = privateKeyPath
        self.savePassword = savePassword
        self.description = description
        self.tags = tags
        self.iconName = iconName
        self.folderId = folderId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties
    var displayHost: String {
        if port == 22 {
            return host
        }
        return "\(host):\(port)"
    }

    var connectionString: String {
        "\(username)@\(displayHost)"
    }

    var hasDescription: Bool {
        description?.isBlank == false
    }

    var hasTags: Bool {
        !tags.isEmpty
    }

    // MARK: - Methods
    func withUpdatedTimestamp() -> Connection {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }
}

// MARK: - Validation
extension Connection {
    var isValid: Bool {
        !name.isBlank &&
        !host.isBlank &&
        !username.isBlank &&
        port > 0 && port <= 65535 &&
        (authMethod == .password || privateKeyPath != nil)
    }

    var validationErrors: [String] {
        var errors: [String] = []
        if name.isBlank {
            errors.append("Name is required")
        }
        if host.isBlank {
            errors.append("Host is required")
        }
        if username.isBlank {
            errors.append("Username is required")
        }
        if port <= 0 || port > 65535 {
            errors.append("Port must be between 1 and 65535")
        }
        if authMethod == .privateKey && (privateKeyPath?.isBlank ?? true) {
            errors.append("Private key path is required for key authentication")
        }
        return errors
    }
}
