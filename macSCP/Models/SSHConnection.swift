//
//  SSHConnection.swift
//  macSCP
//
//  SSH Connection Model
//

import Foundation
import SwiftData

enum AuthenticationType: String, Codable {
    case password
    case key
}

@Model
class SSHConnection {
    var id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var timestamp: Date
    var authenticationType: AuthenticationType?
    var privateKeyPath: String? // Path to the SSH key file
    var savePassword: Bool?
    var connectionDescription: String? // Description of the connection
    var tagsString: String? // Internal storage for tags as comma-separated string
    var iconName: String? // SF Symbol name for custom icon
    var connectionType: ConnectionType = ConnectionType.sftp

    var folder: ConnectionFolder?

    // Computed property for backwards compatibility
    var authType: AuthenticationType {
        get { authenticationType ?? .password }
        set { authenticationType = newValue }
    }

    var shouldSavePassword: Bool {
        get { savePassword ?? false }
        set { savePassword = newValue }
    }

    var displayDescription: String {
        get { connectionDescription ?? "" }
        set { connectionDescription = newValue.isEmpty ? nil : newValue }
    }

    var connectionTags: [String] {
        get { 
            guard let tagsString = tagsString, !tagsString.isEmpty else { return [] }
            return tagsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        set { 
            tagsString = newValue.isEmpty ? nil : newValue.joined(separator: ",")
        }
    }

    var displayIcon: String {
        get { iconName ?? "server.rack" }
        set { iconName = newValue }
    }

    init(name: String, host: String, port: Int = 22, username: String, authenticationType: AuthenticationType = .password, privateKeyPath: String? = nil, savePassword: Bool = false, description: String? = nil, tags: [String]? = nil, iconName: String? = nil, folder: ConnectionFolder? = nil) {
        self.id = UUID()
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authenticationType = authenticationType
        self.privateKeyPath = privateKeyPath
        self.savePassword = savePassword
        self.connectionDescription = description
        self.tagsString = tags?.isEmpty == false ? tags!.joined(separator: ",") : nil
        self.iconName = iconName
        self.timestamp = Date()
        self.folder = folder
    }
}
