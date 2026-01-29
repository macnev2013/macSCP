//
//  WindowManager.swift
//  macSCP
//
//  Manages window data passing for multi-window support
//

import Foundation
import SwiftUI
import Combine

// MARK: - Window Data Types
struct FileBrowserWindowData: Sendable {
    let connectionId: UUID
    let connectionName: String
    let host: String
    let port: Int
    let username: String
    let password: String
    let authMethod: AuthMethod
    let privateKeyPath: String?
}

struct FileEditorWindowData: Sendable {
    let filePath: String
    let fileName: String
    let content: String
    let connectionId: UUID
    // Connection details for saving
    let host: String
    let port: Int
    let username: String
    let password: String
    let authMethod: AuthMethod
    let privateKeyPath: String?
}

struct FileInfoWindowData: Sendable {
    let file: RemoteFile
    let connectionName: String
}

// MARK: - Window Manager
@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()

    private var fileBrowserData: [String: FileBrowserWindowData] = [:]
    private var fileEditorData: [String: FileEditorWindowData] = [:]
    private var fileInfoData: [String: FileInfoWindowData] = [:]

    private init() {}

    // MARK: - File Browser Window
    func storeFileBrowserData(_ data: FileBrowserWindowData) -> String {
        let id = UUID().uuidString
        fileBrowserData[id] = data
        return id
    }

    func getFileBrowserData(for id: String) -> FileBrowserWindowData? {
        fileBrowserData[id]
    }

    func removeFileBrowserData(for id: String) {
        fileBrowserData.removeValue(forKey: id)
    }

    // MARK: - File Editor Window
    func storeFileEditorData(_ data: FileEditorWindowData) -> String {
        let id = UUID().uuidString
        fileEditorData[id] = data
        return id
    }

    func getFileEditorData(for id: String) -> FileEditorWindowData? {
        fileEditorData[id]
    }

    func removeFileEditorData(for id: String) {
        fileEditorData.removeValue(forKey: id)
    }

    // MARK: - File Info Window
    func storeFileInfoData(_ data: FileInfoWindowData) -> String {
        let id = UUID().uuidString
        fileInfoData[id] = data
        return id
    }

    func getFileInfoData(for id: String) -> FileInfoWindowData? {
        fileInfoData[id]
    }

    func removeFileInfoData(for id: String) {
        fileInfoData.removeValue(forKey: id)
    }

    // MARK: - Cleanup
    func clearAllData() {
        fileBrowserData.removeAll()
        fileEditorData.removeAll()
        fileInfoData.removeAll()
    }
}
