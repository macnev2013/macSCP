//
//  ConnectionFolder.swift
//  macSCP
//
//  Folder for organizing SSH connections
//

import Foundation
import SwiftData

@Model
class ConnectionFolder {
    var id: UUID
    var name: String
    var timestamp: Date

    @Relationship(deleteRule: .cascade, inverse: \SSHConnection.folder)
    var connections: [SSHConnection]

    @Relationship(deleteRule: .cascade, inverse: \S3Connection.folder)
    var s3Connections: [S3Connection]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.timestamp = Date()
        self.connections = []
        self.s3Connections = []
    }
}
