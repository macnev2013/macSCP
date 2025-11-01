//
//  AllConnectionsView.swift
//  macSCP
//
//  View displaying all connections across all folders
//

import SwiftUI
import SwiftData

struct AllConnectionsView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext

    let allConnections: [SSHConnection]
    let s3Connections: [S3Connection]

    @State private var showingNewConnectionSheet = false
    @State private var showingNewS3ConnectionSheet = false
    @State private var selectedConnectionId: UUID?
    @State private var selectedConnectionType: ConnectionType?
    @State private var showingPasswordPrompt = false
    @State private var connectionToEdit: SSHConnection?
    @State private var s3ConnectionToEdit: S3Connection?
    @State private var showingDeleteConfirmation = false
    @State private var connectionToDelete: SSHConnection?
    @State private var s3ConnectionToDelete: S3Connection?

    private var selectedConnection: SSHConnection? {
        allConnections.first(where: { $0.id == selectedConnectionId })
    }
    
    private var selectedS3Connection: S3Connection? {
        s3Connections.first(where: { $0.id == selectedConnectionId })
    }

    var body: some View {
        mainContentView
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingNewConnectionSheet) {
                NewSSHConnectionSheetView(folder: nil)
            }
            .sheet(isPresented: $showingNewS3ConnectionSheet, content: {
                NewS3ConnectionSheetView(folder: nil)
            })
            .sheet(isPresented: $showingPasswordPrompt) {
                passwordPromptSheet
            }
            .sheet(item: $connectionToEdit) { connection in
                EditConnectionSheetView(connection: connection)
            }
            .sheet(item: $s3ConnectionToEdit) { connection in
                EditS3ConnectionSheetView(connection: connection)
            }
            .alert("Delete Connection", isPresented: $showingDeleteConfirmation, presenting: connectionToDelete ?? s3ConnectionToDelete as Any) { connection in
                deleteConfirmationButtons
            } message: { connection in
                if let sshConnection = connection as? SSHConnection {
                    Text("Are you sure you want to delete '\(sshConnection.name)'? This action cannot be undone.")
                } else if let s3Connection = connection as? S3Connection {
                    Text("Are you sure you want to delete '\(s3Connection.name)'? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this connection? This action cannot be undone.")
                }
            }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        VStack(spacing: 0) {
            if allConnections.isEmpty && s3Connections.isEmpty {
                EmptyAllConnectionsView(onAddConnection: { showingNewConnectionSheet = true })
            } else {
                connectionsGridView
            }
        }
    }
    
    @ViewBuilder
    private var connectionsGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 320, maximum: 450), spacing: 16)
            ], spacing: 16) {
                // SSH Connections
                ForEach(allConnections) { connection in
                    connectionCardButton(for: connection)
                }
                
                // S3 Connections
                ForEach(s3Connections) { connection in
                    s3ConnectionCardButton(for: connection)
                }
            }
            .padding(16)
        }
        .contentMargins(.all, 0, for: .scrollContent)
    }
    
    @ViewBuilder
    private func connectionCardButton(for connection: SSHConnection) -> some View {
        Button(action: {
            selectedConnectionId = connection.id
            selectedConnectionType = .sftp
        }) {
            ConnectionCardView(
                connection: connection,
                isSelected: selectedConnectionId == connection.id && selectedConnectionType == .sftp
            )
        }
        .buttonStyle(.plain)
        .onTapGesture(count: 2) {
            handleConnect(connection)
        }
        .contextMenu {
            connectionContextMenu(for: connection)
        }
    }
    
    @ViewBuilder
    private func s3ConnectionCardButton(for connection: S3Connection) -> some View {
        Button(action: {
            selectedConnectionId = connection.id
            selectedConnectionType = .s3
        }) {
            S3ConnectionCardView(
                connection: connection,
                isSelected: selectedConnectionId == connection.id && selectedConnectionType == .s3
            )
        }
        .buttonStyle(.plain)
        .onTapGesture(count: 2) {
            handleS3Connect(connection)
        }
        .contextMenu {
            s3ConnectionContextMenu(for: connection)
        }
    }
    
    @ViewBuilder
    private func connectionContextMenu(for connection: SSHConnection) -> some View {
        Button(action: {
            selectedConnectionId = connection.id
            selectedConnectionType = .sftp
            handleConnect(connection)
        }) {
            Label("Connect", systemImage: "arrow.right.circle.fill")
        }

        Divider()

        Button(action: {
            connectionToEdit = connection
        }) {
            Label("Edit Connection", systemImage: "pencil")
        }

        Button(action: {
            duplicateConnection(connection)
        }) {
            Label("Duplicate", systemImage: "doc.on.doc")
        }

        Divider()

        Button(role: .destructive, action: {
            connectionToDelete = connection
            showingDeleteConfirmation = true
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private func s3ConnectionContextMenu(for connection: S3Connection) -> some View {
        Button(action: {
            selectedConnectionId = connection.id
            selectedConnectionType = .s3
            handleS3Connect(connection)
        }) {
            Label("Connect", systemImage: "arrow.right.circle.fill")
        }

        Divider()

        Button(action: {
            s3ConnectionToEdit = connection
        }) {
            Label("Edit Connection", systemImage: "pencil")
        }

        Button(action: {
            duplicateS3Connection(connection)
        }) {
            Label("Duplicate", systemImage: "doc.on.doc")
        }

        Divider()

        Button(role: .destructive, action: {
            s3ConnectionToDelete = connection
            showingDeleteConfirmation = true
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button(action: { showingNewConnectionSheet = true }) {
                Label("New SSH Connection", systemImage: "plus")
            }
        }
        ToolbarItem(placement: .automatic) {
            Button(action: { showingNewS3ConnectionSheet = true }) {
                Label("New S3 Connection", systemImage: "externaldrive.connected.to.line.below")
            }
        }
    }
    
    @ViewBuilder
    private var passwordPromptSheet: some View {
        if let connection = selectedConnection, selectedConnectionType == .sftp {
            PasswordPromptForWindowView(
                connection: connection,
                onConnect: { password in
                    openConnectionWindow(connection: connection, password: password)
                }
            )
        }
    }
    
    @ViewBuilder
    private var deleteConfirmationButtons: some View {
        Button("Cancel", role: .cancel) {
            connectionToDelete = nil
            s3ConnectionToDelete = nil
        }
        Button("Delete", role: .destructive) {
            if let connection = connectionToDelete {
                deleteConnection(connection)
            } else if let connection = s3ConnectionToDelete {
                deleteS3Connection(connection)
            }
        }
    }

    private func handleConnect(_ connection: SSHConnection) {
        // Check if we have a saved password or using SSH key
        if connection.authType == .key {
            // SSH key authentication - no password needed
            openConnectionWindow(connection: connection, password: "")
        } else if connection.shouldSavePassword {
            // Try to get saved password from keychain
            if let savedPassword = KeychainManager.shared.getPassword(for: connection.id.uuidString) {
                // Use saved password directly
                openConnectionWindow(connection: connection, password: savedPassword)
            } else {
                // Saved password flag is set but password not found - show prompt
                showingPasswordPrompt = true
            }
        } else {
            // No saved password - show prompt
            showingPasswordPrompt = true
        }
    }

    private func openConnectionWindow(connection: SSHConnection, password: String) {
        // Store connection info in UserDefaults temporarily for the new window
        let connectionInfo: [String: Any] = [
            "id": connection.id.uuidString,
            "name": connection.name,
            "host": connection.host,
            "port": connection.port,
            "username": connection.username,
            "password": password
        ]

        UserDefaults.standard.set(connectionInfo, forKey: "pendingConnection_\(connection.id.uuidString)")

        // Open window immediately
        openWindow(id: "ssh-explorer", value: connection.id.uuidString)
        showingPasswordPrompt = false
    }

    private func duplicateConnection(_ connection: SSHConnection) {
        withAnimation {
            // Create a new connection with the same properties
            let duplicatedConnection = SSHConnection(
                name: "\(connection.name) Copy",
                host: connection.host,
                port: connection.port,
                username: connection.username,
                authenticationType: connection.authType,
                privateKeyPath: connection.privateKeyPath,
                savePassword: connection.shouldSavePassword,
                description: connection.displayDescription.isEmpty ? nil : connection.displayDescription,
                tags: connection.connectionTags.isEmpty ? nil : connection.connectionTags,
                iconName: connection.iconName,
                folder: connection.folder
            )

            modelContext.insert(duplicatedConnection)

            // Copy password from keychain if it exists
            if connection.shouldSavePassword {
                if let savedPassword = KeychainManager.shared.getPassword(for: connection.id.uuidString) {
                    _ = KeychainManager.shared.savePassword(savedPassword, for: duplicatedConnection.id.uuidString)
                }
            }

            // Save changes immediately
            do {
                try modelContext.save()
            } catch {
                print("Failed to duplicate connection: \(error)")
            }
        }
    }

    private func deleteConnection(_ connection: SSHConnection) {
        withAnimation {
            // Delete saved password from keychain if it exists
            if connection.shouldSavePassword {
                _ = KeychainManager.shared.deletePassword(for: connection.id.uuidString)
            }

            // Clear selection if deleting the selected connection
            if selectedConnectionId == connection.id {
                selectedConnectionId = nil
                selectedConnectionType = nil
            }

            // Delete the connection
            modelContext.delete(connection)

            // Save changes immediately
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete connection: \(error)")
            }

            connectionToDelete = nil
        }
    }

    private func handleS3Connect(_ connection: S3Connection) {
        // For S3 connections, we can connect directly without password prompt
        // TODO: Implement S3 connection window opening
        print("Connecting to S3: \(connection.name)")
        // You can implement S3 connection logic here
    }

    private func duplicateS3Connection(_ connection: S3Connection) {
        withAnimation {
            // Create a new S3 connection with the same properties
            let duplicatedConnection = S3Connection(
                name: "\(connection.name) Copy",
                endpoint: connection.endpoint,
                accessKeyId: connection.accessKeyId,
                secretAccessKey: connection.secretAccessKey,
                connectionDescription: connection.displayDescription.isEmpty ? nil : connection.displayDescription,
                tags: connection.connectionTags.isEmpty ? nil : connection.connectionTags,
                iconName: connection.iconName,
                folder: connection.folder
            )

            modelContext.insert(duplicatedConnection)

            // Save changes immediately
            do {
                try modelContext.save()
            } catch {
                print("Failed to duplicate S3 connection: \(error)")
            }
        }
    }

    private func deleteS3Connection(_ connection: S3Connection) {
        withAnimation {
            // Clear selection if deleting the selected connection
            if selectedConnectionId == connection.id {
                selectedConnectionId = nil
                selectedConnectionType = nil
            }

            // Delete the connection
            modelContext.delete(connection)

            // Save changes immediately
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete S3 connection: \(error)")
            }

            s3ConnectionToDelete = nil
        }
    }
}
