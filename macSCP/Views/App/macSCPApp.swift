//
//  macSCPApp.swift
//  macSCP
//
//  Created by Nevil Macwan on 09/10/25.
//

import SwiftUI
import SwiftData

@main
struct macSCPApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            // Try to create the container with auto-migration
            let container = try ModelContainer(
                for: SSHConnection.self, ConnectionFolder.self, S3Connection.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            return container
        } catch {
            // If migration fails, reset the database
            print("Failed to create ModelContainer with error: \(error)")
            print("Attempting to reset database...")

            // Get the default store URL and delete it
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let bundleID = Bundle.main.bundleIdentifier ?? "com.macSCP"
            let storeURL = appSupport.appendingPathComponent(bundleID).appendingPathComponent("default.store")

            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))

            // Try again with a clean slate
            do {
                let container = try ModelContainer(
                    for: SSHConnection.self, ConnectionFolder.self, S3Connection.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: false)
                )
                return container
            } catch {
                fatalError("Could not create ModelContainer even after reset: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)

        WindowGroup(id: "ssh-explorer", for: String.self) { $connectionId in
            if let connectionId = connectionId {
                SSHFileExplorerWindow(connectionId: connectionId)
            }
        }
        .modelContainer(sharedModelContainer)

        WindowGroup(id: "file-editor", for: String.self) { $editorId in
            if let editorId = editorId {
                FileEditorWindowView(editorId: editorId)
            }
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1000, height: 700)

        WindowGroup(id: "file-info", for: String.self) { $infoId in
            if let infoId = infoId {
                FileInfoContainerView(infoId: infoId)
            }
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 400, height: 500)
        .windowResizability(.contentSize)
    }
}
