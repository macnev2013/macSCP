//
//  S3Connection.swift
//  macSCP
//
//  Created by Nevil Macwan on 01/11/25.
//


import Foundation
import SwiftData

@Model
class S3Connection {
    var id: UUID
    var name: String
    var endpoint: String?
    var accessKeyId: String
    var secretAccessKey: String
    var timestamp: Date
    var connectionDescription: String? // Description of the connection
    var tagsString: String? // Internal storage for tags as comma-separated string
    var iconName: String? // SF Symbol name for custom icon
    var connectionType: ConnectionType = ConnectionType.s3

    var folder: ConnectionFolder?

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

    init(name: String, endpoint: String? = nil, accessKeyId: String, secretAccessKey: String, connectionDescription: String? = nil, tags: [String]? = nil, iconName: String? = nil, folder: ConnectionFolder? = nil) {
        self.id = UUID()
        self.name = name
        self.endpoint = endpoint
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.connectionDescription = connectionDescription
        self.tagsString = tags?.isEmpty == false ? tags!.joined(separator: ",") : nil
        self.iconName = iconName
        self.folder = folder
        self.timestamp = Date()
    }
}
