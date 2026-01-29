//
//  BadgeView.swift
//  macSCP
//
//  Count badge view component
//

import SwiftUI

struct BadgeView: View {
    let count: Int
    let color: Color

    init(count: Int, color: Color = .blue) {
        self.count = count
        self.color = color
    }

    var body: some View {
        Text("\(count)")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color, in: Capsule())
    }

    var displayText: String {
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
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color, in: Capsule())
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

            if count > 0 {
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(color, in: Circle())
                    .offset(x: 8, y: -8)
            }
        }
    }
}

// MARK: - Preview
#Preview("Badge") {
    HStack(spacing: 20) {
        BadgeView(count: 5)
        BadgeView(count: 99, color: .red)
        BadgeView(count: 150, color: .green)
    }
    .padding()
}

#Preview("Large Badge") {
    HStack(spacing: 20) {
        LargeBadgeView(count: 3, label: "items")
        LargeBadgeView(count: 12, label: "files", color: .green)
    }
    .padding()
}

#Preview("Icon Badge") {
    HStack(spacing: 30) {
        IconBadgeView(icon: "doc.on.clipboard", count: 2)
        IconBadgeView(icon: "folder", count: 0)
        IconBadgeView(icon: "bell", count: 100, color: .orange)
    }
    .padding()
}
