//
//  ConnectionFormSheet.swift
//  macSCP
//
//  Form for creating and editing connections
//

import SwiftUI

enum ConnectionFormMode {
    case create
    case edit(Connection)

    var title: String {
        switch self {
        case .create: return "New Connection"
        case .edit: return "Edit Connection"
        }
    }

    var saveButtonTitle: String {
        switch self {
        case .create: return "Create"
        case .edit: return "Save"
        }
    }
}

struct ConnectionFormSheet: View {
    let mode: ConnectionFormMode
    let savedPassword: String?
    let onSave: (Connection, String?) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = "22"
    @State private var username: String = ""
    @State private var authMethod: AuthMethod = .password
    @State private var privateKeyPath: String = ""
    @State private var savePassword: Bool = false
    @State private var password: String = ""
    @State private var description: String = ""
    @State private var iconName: String = "server.rack"

    init(
        mode: ConnectionFormMode,
        savedPassword: String? = nil,
        onSave: @escaping (Connection, String?) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.mode = mode
        self.savedPassword = savedPassword
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(mode.title)
                    .font(.headline)
                Spacer()
                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section("Connection") {
                    TextField("Name", text: $name)
                    TextField("Host", text: $host)
                    TextField("Port", text: $port)
                    TextField("Username", text: $username)
                }

                Section("Authentication") {
                    Picker("Method", selection: $authMethod) {
                        ForEach(AuthMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }

                    if authMethod == .password {
                        SecureField("Password", text: $password)
                        Toggle("Save password in Keychain", isOn: $savePassword)
                    } else {
                        HStack {
                            TextField("Private Key Path", text: $privateKeyPath)
                            Button("Browse") {
                                browseForKey()
                            }
                        }
                    }
                }

                Section("Optional") {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)

                    Picker("Icon", selection: $iconName) {
                        Label("Server Rack", systemImage: "server.rack").tag("server.rack")
                        Label("Desktop", systemImage: "desktopcomputer").tag("desktopcomputer")
                        Label("Laptop", systemImage: "laptopcomputer").tag("laptopcomputer")
                        Label("Cloud", systemImage: "cloud").tag("cloud")
                        Label("Network", systemImage: "network").tag("network")
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            // Footer
            HStack {
                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button(mode.saveButtonTitle) {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 450, height: 550)
        .onAppear {
            loadExistingData()
        }
    }

    private var isValid: Bool {
        !name.trimmed.isEmpty &&
        !host.trimmed.isEmpty &&
        !username.trimmed.isEmpty &&
        (Int(port) ?? 0) > 0 && (Int(port) ?? 0) <= 65535 &&
        (authMethod == .password || !privateKeyPath.trimmed.isEmpty)
    }

    private func loadExistingData() {
        if case .edit(let connection) = mode {
            name = connection.name
            host = connection.host
            port = String(connection.port)
            username = connection.username
            authMethod = connection.authMethod
            privateKeyPath = connection.privateKeyPath ?? ""
            savePassword = connection.savePassword
            description = connection.description ?? ""
            iconName = connection.iconName

            if let saved = savedPassword {
                password = saved
            }
        }
    }

    private func save() {
        let portNumber = Int(port) ?? 22

        let connection: Connection
        if case .edit(let existing) = mode {
            connection = Connection(
                id: existing.id,
                name: name.trimmed,
                host: host.trimmed,
                port: portNumber,
                username: username.trimmed,
                authMethod: authMethod,
                privateKeyPath: authMethod == .privateKey ? privateKeyPath.trimmed : nil,
                savePassword: savePassword,
                description: description.trimmed.isEmpty ? nil : description.trimmed,
                iconName: iconName,
                folderId: existing.folderId,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else {
            connection = Connection(
                name: name.trimmed,
                host: host.trimmed,
                port: portNumber,
                username: username.trimmed,
                authMethod: authMethod,
                privateKeyPath: authMethod == .privateKey ? privateKeyPath.trimmed : nil,
                savePassword: savePassword,
                description: description.trimmed.isEmpty ? nil : description.trimmed,
                iconName: iconName
            )
        }

        let passwordToSave = savePassword && !password.isEmpty ? password : nil
        onSave(connection, passwordToSave)
    }

    private func browseForKey() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")

        if panel.runModal() == .OK, let url = panel.url {
            privateKeyPath = url.path
        }
    }
}

// MARK: - Preview
#Preview("Create") {
    ConnectionFormSheet(
        mode: .create,
        onSave: { _, _ in },
        onCancel: {}
    )
}

#Preview("Edit") {
    ConnectionFormSheet(
        mode: .edit(Connection(
            name: "Test Server",
            host: "test.example.com",
            username: "admin"
        )),
        savedPassword: "secret123",
        onSave: { _, _ in },
        onCancel: {}
    )
}
