//
//  NewConnectionSheetView.swift
//  macSCP
//
//  Sheet for creating a new SSH connection
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct NewSSHConnectionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let folder: ConnectionFolder?

    @State private var connectionName = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var connectionDescription = ""
    @State private var tagsInput = ""
    @State private var selectedIcon = "server.rack"
    @State private var showingIconPicker = false
    @State private var authenticationType: AuthenticationType = .password
    @State private var password = ""
    @State private var savePassword = false
    @State private var privateKeyPath = ""
    @State private var showingFilePicker = false

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
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("New SSH Connection")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Configure your SSH connection settings")
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

                //Icon Picker
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
                        Text("Password (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        SecureField("Leave empty to prompt on connect", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: password) { oldValue, newValue in
                                // Auto-enable save password when user enters a password
                                if !newValue.isEmpty && !savePassword {
                                    savePassword = true
                                }
                            }

                        Toggle("Save password in Keychain", isOn: $savePassword)
                            .font(.caption)
                            .disabled(password.isEmpty)
                            .onChange(of: savePassword) { oldValue, newValue in
                                // Clear password if user unchecks the toggle
                                if !newValue {
                                    password = ""
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

                Button("Create Connection") {
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

        let connection = SSHConnection(
            name: connectionName.trimmingCharacters(in: .whitespacesAndNewlines),
            host: host.trimmingCharacters(in: .whitespacesAndNewlines),
            port: portNumber,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            authenticationType: authenticationType,
            privateKeyPath: authenticationType == .key ? privateKeyPath : nil,
            savePassword: savePassword && !password.isEmpty,
            description: connectionDescription.isEmpty ? nil : connectionDescription,
            tags: parsedTags.isEmpty ? nil : parsedTags,
            iconName: selectedIcon == "server.rack" ? nil : selectedIcon,
            folder: folder
        )

        modelContext.insert(connection)

        do {
            try modelContext.save()

            // Save password to keychain if requested
            if savePassword && !password.isEmpty && authenticationType == .password {
                _ = KeychainManager.shared.savePassword(password, for: connection.id.uuidString)
            }
        } catch {
            print("Failed to save connection: \(error)")
        }

        dismiss()
    }
}
