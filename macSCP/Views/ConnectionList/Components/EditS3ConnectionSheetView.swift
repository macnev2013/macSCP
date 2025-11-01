//
//  EditS3ConnectionSheetView.swift
//  macSCP
//
//  Sheet view for editing existing S3 connections
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct EditS3ConnectionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var connection: S3Connection

    @State private var connectionName = ""
    @State private var endpoint = ""
    @State private var accessKeyId = ""
    @State private var secretAccessKey = ""
    @State private var connectionDescription = ""
    @State private var tagsInput = ""
    @State private var selectedIcon = "server.rack"
    @State private var showingIconPicker = false
    @State private var secretKeyChanged = false
    @State private var originalSecretKey = ""

    var isFormValid: Bool {
        !connectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !accessKeyId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !secretAccessKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit S3 Connection")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Update your S3 connection settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Form Fields
            VStack(spacing: 16) {
                // Connection Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Connection Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., Production Asset Bucket", text: $connectionName)
                        .textFieldStyle(.roundedBorder)
                }

                // Custom Endpoint
                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom Endpoint (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., s3.localhost.localstack.cloud", text: $endpoint)
                        .textFieldStyle(.roundedBorder)
                    Text("Leave empty for default AWS S3 endpoint")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Access Key ID
                VStack(alignment: .leading, spacing: 6) {
                    Text("Access Key ID")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., AKIAIOSFODNN7EXAMPLE", text: $accessKeyId)
                        .textFieldStyle(.roundedBorder)
                }

                // Secret Access Key
                VStack(alignment: .leading, spacing: 6) {
                    Text("Secret Access Key")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    SecureField("Enter new secret key to change", text: $secretAccessKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: secretAccessKey) { _, newValue in
                            if !secretKeyChanged && newValue != originalSecretKey {
                                secretKeyChanged = true
                            }
                        }
                    if !secretKeyChanged {
                        Text("Using existing secret key (hidden for security)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("New secret key will be saved")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
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
            }

            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save Changes") {
                    saveChanges()
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
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $selectedIcon)
        }
        .onAppear {
            loadConnectionData()
        }
    }

    private func loadConnectionData() {
        connectionName = connection.name
        endpoint = connection.endpoint ?? ""
        accessKeyId = connection.accessKeyId
        // Store a masked version for comparison
        originalSecretKey = String(repeating: "*", count: 16)
        secretAccessKey = originalSecretKey
        connectionDescription = connection.displayDescription
        tagsInput = connection.connectionTags.joined(separator: ", ")
        selectedIcon = connection.displayIcon
    }

    private func saveChanges() {
        // Parse tags from comma-separated input
        let parsedTags = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Update connection properties
        connection.name = connectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        connection.endpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        connection.accessKeyId = accessKeyId.trimmingCharacters(in: .whitespacesAndNewlines)

        // Only update secret key if it was changed
        if secretKeyChanged && secretAccessKey != originalSecretKey {
            connection.secretAccessKey = secretAccessKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        connection.connectionDescription = connectionDescription.isEmpty ? nil : connectionDescription
        connection.connectionTags = parsedTags
        connection.iconName = selectedIcon == "server.rack" ? nil : selectedIcon

        do {
            try modelContext.save()
        } catch {
            print("Failed to save changes: \(error)")
        }

        dismiss()
    }
}

#Preview {
    EditS3ConnectionSheetView(
        connection: S3Connection(
            name: "Test S3",
            endpoint: "s3.amazonaws.com",
            accessKeyId: "AKIAIOSFODNN7EXAMPLE",
            secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        )
    )
    .modelContainer(for: [S3Connection.self], inMemory: true)
}