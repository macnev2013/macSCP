//
//  ConnectionCardView.swift
//  macSCP
//
//  Card displaying SSH connection information
//

import SwiftUI

struct SSHConnectionCardView: View {
    let connection: SSHConnection
    let isSelected: Bool
    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with icon and name
            HStack(spacing: 12) {
                Image(systemName: connection.displayIcon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
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
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.blue.opacity(0.1))
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

//            Divider()
//                .background(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.2))

            // Connection info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "network")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 14)

                    Text("\(connection.username)@\(connection.host):\(String(connection.port))")
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

// MARK: - Flow Layout for Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
