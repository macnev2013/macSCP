//
//  AuthMethod.swift
//  macSCP
//
//  Authentication method types for SSH connections
//

import Foundation

enum AuthMethod: String, Codable, Sendable, CaseIterable {
    case password
    case privateKey

    var displayName: String {
        switch self {
        case .password:
            return "Password"
        case .privateKey:
            return "Private Key"
        }
    }

    var iconName: String {
        switch self {
        case .password:
            return "key.fill"
        case .privateKey:
            return "doc.text.fill"
        }
    }
}
