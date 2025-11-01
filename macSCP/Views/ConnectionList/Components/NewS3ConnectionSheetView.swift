//
//  NewS3ConnectionSheetView.swift
//  macSCP
//
//  Created by Nevil Macwan on 01/11/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct NewS3ConnectionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let folder: ConnectionFolder?
    
    @State private var connectionName = ""
    @State private var endpoint = ""
    @State private var accessKeyId = ""
    @State private var secretAccessKey = ""
    @State private var region: String?
    @State private var connectionDescription = ""
    @State private var tagsInput = ""
    @State private var selectedIcon = "server.rack"
    @State private var showingIconPicker = false
    
    var isFormValid: Bool {
        !connectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("New S3 Connection")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Configure your S3 connection settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            
            
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
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Custom Endpoint")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("e.g., s3.localhost.localstack.cloud", text: $endpoint)
                            .textFieldStyle(.roundedBorder)
                    }

                }

                // Username
                VStack(alignment: .leading, spacing: 6) {
                    Text("Access Key ID")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., AKIAIOSFODNN7EXAMPLE", text: $accessKeyId)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Secret Access Key")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., wJalrXUtnKu3Vy3T4nXXeXXSqR6IrCdT0NvDOqoE1bmN5Tae5Aoz...", text: $secretAccessKey)
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
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $selectedIcon)
        }
    }
    
    private func saveConnection() {
        // Parse tags from comma-separated input
        let parsedTags = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let connection = S3Connection(
            name: connectionName.trimmingCharacters(in: .whitespacesAndNewlines),
            endpoint: endpoint.trimmingCharacters(in: .whitespacesAndNewlines),
            accessKeyId: accessKeyId.trimmingCharacters(in: .whitespacesAndNewlines),
            secretAccessKey: secretAccessKey.trimmingCharacters(in: .whitespacesAndNewlines),
            connectionDescription: connectionDescription.isEmpty ? nil : connectionDescription,
            tags: parsedTags.isEmpty ? nil : parsedTags,
            iconName: selectedIcon == "server.rack" ? nil : selectedIcon,
            folder: folder
        )

        modelContext.insert(connection)

        do {
            try modelContext.save()
//            // Save password to keychain if requested
//            if savePassword && !password.isEmpty && authenticationType == .password {
//                _ = KeychainManager.shared.savePassword(password, for: connection.id.uuidString)
//            }
        } catch {
            print("Failed to save connection: \(error)")
        }

        dismiss()
    }
}

