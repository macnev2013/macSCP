//
//  MacSCPApp.swift
//  macSCP
//
//  Main application entry point
//

import SwiftUI
import SwiftData
#if !MAS_BUILD
import Sparkle
#endif

@main
struct MacSCPApp: App {
    @StateObject private var container = DependencyContainer.shared

    #if !MAS_BUILD
    private let updaterController: SPUStandardUpdaterController
    @StateObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    #endif

    init() {
        AnalyticsService.initialize()
        AppLockManager.shared.lockIfNeeded()

        #if !MAS_BUILD
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.updaterController = controller
        self._checkForUpdatesViewModel = StateObject(
            wrappedValue: CheckForUpdatesViewModel(updater: controller.updater)
        )
        #endif
    }

    var body: some Scene {
        // Main Window - Connection List
        WindowGroup {
            ConnectionListView(viewModel: container.makeConnectionListViewModel())
                .appLockOverlay()
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
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.fileBrowser)

        // File Editor Window
        WindowGroup(id: WindowID.fileEditor, for: String.self) { $windowId in
            if let windowId = windowId {
                FileEditorWindow(windowId: windowId)
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.fileEditor)

        // File Info Window
        WindowGroup(id: WindowID.fileInfo, for: String.self) { $windowId in
            if let windowId = windowId {
                FileInfoWindow(windowId: windowId)
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.fileInfo)
        .windowResizability(.contentSize)

        // Terminal Window
        WindowGroup(id: WindowID.terminal, for: String.self) { $windowId in
            if let windowId = windowId {
                TerminalWindow(windowId: windowId)
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.terminal)

        // Settings Window (Cmd+,)
        Settings {
            SettingsView()
                .appLockOverlay()
        }
    }

    // MARK: - Commands
    @CommandsBuilder
    private var appCommands: some Commands {
        #if !MAS_BUILD
        CommandGroup(after: .appInfo) {
            CheckForUpdatesView(viewModel: checkForUpdatesViewModel)
        }
        #endif

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

        CommandGroup(replacing: .help) {
            Button("Report a Bug…") {
                if let url = URL(string: "https://github.com/macnev2013/macSCP/issues") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
