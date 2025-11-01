//
//  EditConnectionSheetView.swift
//  macSCP
//
//  Sheet for editing an existing SSH connection
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct EditSSHConnectionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var connection: SSHConnection

    @State private var connectionName: String
    @State private var host: String
    @State private var port: String
    @State private var username: String
    @State private var connectionDescription: String
    @State private var tagsInput: String
    @State private var selectedIcon: String
    @State private var showingIconPicker = false
    @State private var authenticationType: AuthenticationType
    @State private var password = ""
    @State private var savePassword: Bool
    @State private var privateKeyPath: String
    @State private var showingFilePicker = false
    @State private var passwordChanged = false

    init(connection: SSHConnection) {
        self.connection = connection
        _connectionName = State(initialValue: connection.name)
        _host = State(initialValue: connection.host)
        _port = State(initialValue: String(connection.port))
        _username = State(initialValue: connection.username)
        _connectionDescription = State(initialValue: connection.displayDescription)
        _tagsInput = State(initialValue: connection.connectionTags.joined(separator: ", "))
        _selectedIcon = State(initialValue: connection.displayIcon)
        _authenticationType = State(initialValue: connection.authType)
        _savePassword = State(initialValue: connection.shouldSavePassword)
        _privateKeyPath = State(initialValue: connection.privateKeyPath ?? "")
    }

    var isFormValid: Bool {
        !connectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(port) != nil &&
        (authenticationType == .password ? true : !privateKeyPath.isEmpty)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Connection")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Update your SSH connection settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Form fields
            VStack(spacing: 16) {
                // Connection Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Connection Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., Production Server", text: $connectionName)
                        .textFieldStyle(.roundedBorder)
                }

                // Host and Port
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Host")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("e.g., 192.168.1.1", text: $host)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Port")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("22", text: $port)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }

                // Username
                VStack(alignment: .leading, spacing: 6) {
                    Text("Username")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., root", text: $username)
                        .textFieldStyle(.roundedBorder)
                }

                // Icon Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Icon")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Button(action: { showingIconPicker.toggle() }) {
                        HStack {
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Choose Icon")
                                .font(.body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., Production database server", text: $connectionDescription)
                        .textFieldStyle(.roundedBorder)
                }

                // Tags
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tags (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., production, database, critical", text: $tagsInput)
                        .textFieldStyle(.roundedBorder)
                    Text("Separate tags with commas")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Authentication Type
                VStack(alignment: .leading, spacing: 6) {
                    Text("Authentication")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("", selection: $authenticationType) {
                        Text("Password").tag(AuthenticationType.password)
                        Text("SSH Key").tag(AuthenticationType.key)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                // Authentication-specific fields
                if authenticationType == .password {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if connection.shouldSavePassword && !passwordChanged {
                                Text("(currently saved)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        SecureField(connection.shouldSavePassword && !passwordChanged ? "Enter new password to update" : "Enter password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: password) { oldValue, newValue in
                                passwordChanged = !newValue.isEmpty
                                // Auto-enable save password when user enters a password
                                if !newValue.isEmpty && !savePassword {
                                    savePassword = true
                                }
                            }

                        Toggle("Save password in Keychain", isOn: $savePassword)
                            .font(.caption)
                            .disabled(password.isEmpty && !connection.shouldSavePassword)
                            .onChange(of: savePassword) { oldValue, newValue in
                                // Clear password if user unchecks the toggle
                                if !newValue && passwordChanged {
                                    password = ""
                                    passwordChanged = false
                                }
                            }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Private Key Path")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            TextField("e.g., ~/.ssh/id_rsa", text: $privateKeyPath)
                                .textFieldStyle(.roundedBorder)

                            Button("Browse...") {
                                showingFilePicker = true
                            }
                        }
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save Changes") {
                    saveConnection()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid)
            }
            .padding(.top, 8)
        }
        .padding(30)
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    privateKeyPath = url.path
                }
            case .failure(let error):
                print("File picker error: \(error)")
            }
        }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $selectedIcon)
        }
    }

    private func saveConnection() {
        guard let portNumber = Int(port) else { return }

        // Parse tags from comma-separated input
        let parsedTags = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Update connection properties
        connection.name = connectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        connection.host = host.trimmingCharacters(in: .whitespacesAndNewlines)
        connection.port = portNumber
        connection.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        connection.connectionDescription = connectionDescription.isEmpty ? nil : connectionDescription
        connection.connectionTags = parsedTags
        connection.iconName = selectedIcon == "server.rack" ? nil : selectedIcon
        connection.authenticationType = authenticationType
        connection.privateKeyPath = authenticationType == .key ? privateKeyPath : nil
        connection.savePassword = savePassword

        do {
            try modelContext.save()

            // Handle password changes
            if authenticationType == .password {
                if passwordChanged && !password.isEmpty && savePassword {
                    // User entered a new password - save it
                    _ = KeychainManager.shared.updatePassword(password, for: connection.id.uuidString)
                } else if !savePassword && connection.shouldSavePassword {
                    // User disabled password saving - delete from keychain
                    _ = KeychainManager.shared.deletePassword(for: connection.id.uuidString)
                }
            } else {
                // Switched to key-based auth - delete any saved password
                _ = KeychainManager.shared.deletePassword(for: connection.id.uuidString)
            }
        } catch {
            print("Failed to save connection: \(error)")
        }

        dismiss()
    }
}
