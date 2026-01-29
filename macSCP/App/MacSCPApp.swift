//
//  MacSCPApp.swift
//  macSCP
//
//  Main application entry point
//

import SwiftUI
import SwiftData

@main
struct MacSCPApp: App {
    @StateObject private var container = DependencyContainer.shared

    var body: some Scene {
        // Main Window - Connection List
        WindowGroup {
            ConnectionListView(viewModel: container.makeConnectionListViewModel())
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.main)
        .commands {
            appCommands
        }

        // File Browser Window
        WindowGroup(id: WindowID.fileBrowser, for: String.self) { $windowId in
            if let windowId = windowId {
                FileBrowserWindow(windowId: windowId)
            }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.fileBrowser)

        // File Editor Window
        WindowGroup(id: WindowID.fileEditor, for: String.self) { $windowId in
            if let windowId = windowId {
                FileEditorWindow(windowId: windowId)
            }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.fileEditor)

        // File Info Window
        WindowGroup(id: WindowID.fileInfo, for: String.self) { $windowId in
            if let windowId = windowId {
                FileInfoWindow(windowId: windowId)
            }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.fileInfo)
        .windowResizability(.contentSize)
    }

    // MARK: - Commands
    @CommandsBuilder
    private var appCommands: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Connection") {
                // Handled by main window
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Folder") {
                // Handled by main window
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandGroup(after: .toolbar) {
            Button("Refresh") {
                // Handled by active window
            }
            .keyboardShortcut("r", modifiers: .command)
        }
    }
}
