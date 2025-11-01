//
//  S3ConnectionCardView.swift
//  macSCP
//
//  Card displaying S3 connection information
//

import SwiftUI

struct S3ConnectionCardView: View {
    let connection: S3Connection
    let isSelected: Bool
    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with icon and name
            HStack(spacing: 12) {
                Image(systemName: connection.displayIcon)
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(connection.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if !connection.connectionTags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(connection.connectionTags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.orange.opacity(0.1))
                                        )
                                }
                                if connection.connectionTags.count > 3 {
                                    Text("+\(connection.connectionTags.count - 3)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    Text(connection.displayDescription.isEmpty ? "-" : connection.displayDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.bottom, 8)

            // Connection info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 14)

                    Text(connection.endpoint ?? "Default Endpoint")
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 14)

                    Text(connection.accessKeyId)
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 14)

                    Text(connection.folder?.name ?? "No Folder")
                        .font(.system(size: 11))
                        .foregroundColor(connection.folder == nil ? .secondary : .primary)
                        .lineLimit(1)
                }
            }
            .padding(.top, 8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(.controlBackgroundColor).opacity(0.5) : Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.accentColor : (isHovered ? Color.gray.opacity(0.5) : Color.gray.opacity(0.2)), lineWidth: isSelected ? 2 : 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}