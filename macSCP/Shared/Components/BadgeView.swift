//
//  BadgeView.swift
//  macSCP
//
//  Count badge view component - Modern macOS style
//

import SwiftUI

struct BadgeView: View {
    let count: Int
    let style: BadgeStyle

    enum BadgeStyle {
        case `default`
        case subtle
        case prominent

        var backgroundColor: Color {
            switch self {
            case .default:
                return .blue
            case .subtle:
                return .secondary.opacity(0.2)
            case .prominent:
                return .red
            }
        }

        var foregroundColor: Color {
            switch self {
            case .default, .prominent:
                return .white
            case .subtle:
                return .secondary
            }
        }
    }

    init(count: Int, style: BadgeStyle = .subtle) {
        self.count = count
        self.style = style
    }

    // Backwards compatibility with color parameter
    init(count: Int, color: Color) {
        self.count = count
        // Map color to style
        if color == .blue {
            self.style = .default
        } else if color == .red {
            self.style = .prominent
        } else {
            self.style = .subtle
        }
    }

    var body: some View {
        Text(displayText)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(style.backgroundColor, in: Capsule())
    }

    private var displayText: String {
        if count > 99 {
            return "99+"
        }
        return "\(count)"
    }
}

// MARK: - Larger Badge
struct LargeBadgeView: View {
    let count: Int
    let label: String
    let color: Color

    init(count: Int, label: String, color: Color = .blue) {
        self.count = count
        self.label = label
        self.color = color
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))

            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            LinearGradient(
                colors: [color, color.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Icon Badge
struct IconBadgeView: View {
    let icon: String
    let count: Int
    let color: Color

    init(icon: String, count: Int, color: Color = .red) {
        self.icon = icon
        self.count = count
        self.color = color
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: icon)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)

            if count > 0 {
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        LinearGradient(
                            colors: [color, color.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: Capsule()
                    )
                    .shadow(color: color.opacity(0.4), radius: 2, x: 0, y: 1)
                    .offset(x: 6, y: -6)
            }
        }
    }
}

// MARK: - Status Badge
struct StatusBadgeView: View {
    let status: Status
    let label: String?

    enum Status {
        case online
        case offline
        case busy
        case away

        var color: Color {
            switch self {
            case .online: return .green
            case .offline: return .gray
            case .busy: return .red
            case .away: return .orange
            }
        }

        var defaultLabel: String {
            switch self {
            case .online: return "Online"
            case .offline: return "Offline"
            case .busy: return "Busy"
            case .away: return "Away"
            }
        }
    }

    init(status: Status, label: String? = nil) {
        self.status = status
        self.label = label
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [status.color.opacity(0.8), status.color],
                        center: .center,
                        startRadius: 0,
                        endRadius: 4
                    )
                )
                .frame(width: 8, height: 8)
                .shadow(color: status.color.opacity(0.5), radius: 2)

            Text(label ?? status.defaultLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.quaternary, in: Capsule())
    }
}

// MARK: - Preview
#Preview("Badge") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            BadgeView(count: 5, style: .default)
            BadgeView(count: 99, style: .prominent)
            BadgeView(count: 150, style: .subtle)
        }

        HStack(spacing: 20) {
            LargeBadgeView(count: 3, label: "items")
            LargeBadgeView(count: 12, label: "files", color: .green)
        }

        HStack(spacing: 30) {
            IconBadgeView(icon: "doc.on.clipboard", count: 2)
            IconBadgeView(icon: "folder", count: 0)
            IconBadgeView(icon: "bell", count: 100, color: .orange)
        }

        HStack(spacing: 16) {
            StatusBadgeView(status: .online)
            StatusBadgeView(status: .busy, label: "Do Not Disturb")
            StatusBadgeView(status: .offline)
        }
    }
    .padding()
}
