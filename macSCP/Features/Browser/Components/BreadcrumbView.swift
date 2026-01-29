//
//  BreadcrumbView.swift
//  macSCP
//
//  Breadcrumb navigation for the file browser
//

import SwiftUI

struct BreadcrumbView: View {
    let components: [PathComponent]
    let onNavigate: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Root
                Button {
                    onNavigate("/")
                } label: {
                    Image(systemName: "externaldrive.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                ForEach(components) { component in
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Button {
                        onNavigate(component.path)
                    } label: {
                        Text(component.name)
                            .font(.callout)
                            .foregroundStyle(component.path == components.last?.path ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .background(Color(.controlBackgroundColor))
    }
}

// MARK: - Preview
#Preview {
    BreadcrumbView(
        components: [
            PathComponent(name: "home", path: "/home"),
            PathComponent(name: "user", path: "/home/user"),
            PathComponent(name: "documents", path: "/home/user/documents")
        ],
        onNavigate: { _ in }
    )
}
