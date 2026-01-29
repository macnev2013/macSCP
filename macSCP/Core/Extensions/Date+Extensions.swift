//
//  Date+Extensions.swift
//  macSCP
//
//  Date formatting extensions
//

import Foundation

extension Date {
    /// Formats the date for display in file listings
    var fileListDisplayString: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            formatter.dateFormat = "HH:mm"
            return "Today, " + formatter.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            formatter.dateFormat = "HH:mm"
            return "Yesterday, " + formatter.string(from: self)
        } else if calendar.isDate(self, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d, HH:mm"
            return formatter.string(from: self)
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: self)
        }
    }

    /// Formats the date for file info display (full format)
    var fileInfoDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: self)
    }

    /// Returns a short relative time string (e.g., "2h ago", "3d ago")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Returns ISO8601 formatted string
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: self)
    }
}

// MARK: - Date Creation
extension Date {
    /// Creates a Date from Unix timestamp
    static func from(unixTimestamp: Int64) -> Date {
        Date(timeIntervalSince1970: TimeInterval(unixTimestamp))
    }

    /// Creates a Date from ISO8601 string
    static func from(iso8601String: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: iso8601String)
    }
}
