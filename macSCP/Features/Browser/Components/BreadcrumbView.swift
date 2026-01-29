//
//  BreadcrumbView.swift
//  macSCP
//
//  Breadcrumb navigation for the file browser - Modern macOS style
//

import SwiftUI

struct BreadcrumbView: View {
    let components: [PathComponent]
    let onNavigate: (String) -> Void

    @State private var hoveredPath: String?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    // Root
                    BreadcrumbItem(
                        icon: "externaldrive.fill",
                        isHovered: hoveredPath == "/",
                        isLast: components.isEmpty
                    ) {
                        onNavigate("/")
                    }
                    .onHover { hovering in
                        hoveredPath = hovering ? "/" : nil
                    }

                    ForEach(components) { component in
                        // Separator
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.quaternary)
                            .padding(.horizontal, 2)

                        // Path component
                        BreadcrumbItem(
                            text: component.name,
                            isHovered: hoveredPath == component.path,
                            isLast: component.path == components.last?.path
                        ) {
                            onNavigate(component.path)
                        }
                        .onHover { hovering in
                            hoveredPath = hovering ? component.path : nil
                        }
                        .id(component.path)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: components) { _, newComponents in
                if let lastPath = newComponents.last?.path {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(lastPath, anchor: .trailing)
                    }
                }
            }
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Breadcrumb Item
struct BreadcrumbItem: View {
    var icon: String?
    var text: String?
    let isHovered: Bool
    let isLast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                } else if let text = text {
                    Text(text)
                        .font(.system(size: 12, weight: isLast ? .semibold : .medium))
                }
            }
            .foregroundStyle(isLast ? .primary : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.08) : .clear)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        BreadcrumbView(
            components: [],
            onNavigate: { _ in }
        )

        BreadcrumbView(
            components: [
                PathComponent(name: "home", path: "/home"),
                PathComponent(name: "user", path: "/home/user"),
                PathComponent(name: "documents", path: "/home/user/documents")
            ],
            onNavigate: { _ in }
        )

        BreadcrumbView(
            components: [
                PathComponent(name: "var", path: "/var"),
                PathComponent(name: "www", path: "/var/www"),
                PathComponent(name: "html", path: "/var/www/html"),
                PathComponent(name: "myproject", path: "/var/www/html/myproject"),
                PathComponent(name: "src", path: "/var/www/html/myproject/src")
            ],
            onNavigate: { _ in }
        )
    }
    .frame(width: 400)
}
