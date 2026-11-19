import Foundation
import SwiftUI

public struct PaymentDueResponse: Codable {
    public let zeroToThirtyDays: AgingBucket
    public let thirtyOneToSixtyDays: AgingBucket
    public let sixtyPlusDays: AgingBucket
    public let totalOutstanding: Double

    public init(
        zeroToThirtyDays: AgingBucket = AgingBucket(),
        thirtyOneToSixtyDays: AgingBucket = AgingBucket(),
        sixtyPlusDays: AgingBucket = AgingBucket(),
        totalOutstanding: Double = 0.0
    ) {
        self.zeroToThirtyDays = zeroToThirtyDays
        self.thirtyOneToSixtyDays = thirtyOneToSixtyDays
        self.sixtyPlusDays = sixtyPlusDays
        self.totalOutstanding = totalOutstanding
    }
}

public struct AgingBucket: Codable, Identifiable {
    public var id: String { label }
    public let amount: Double
    public let count: Int
    public let label: String
    public let color: String
    public let bg: String

    public init(amount: Double = 0.0, count: Int = 0, label: String = "", color: String = "", bg: String = "") {
        self.amount = amount
        self.count = count
        self.label = label
        self.color = color
        self.bg = bg
    }
}

public struct GrossSalesPoint: Identifiable, Equatable {
    public var id: String { monthKey }
    public let monthKey: String      // "2026-04"
    public let monthLabel: String    // "Apr"
    public let revenueInLakhs: Double
    public let targetInLakhs: Double
    public let rawRevenue: Double
    public let rawTarget: Double
}

public struct AgingChartSegment: Identifiable {
    public var id: String { label }
    public let label: String
    public let amount: Double
    public let percentage: Double
    public let count: Int
    public let color: Color
}

public struct ActivityLog: Codable, Identifiable {
    public var id: String { _id ?? logId ?? UUID().uuidString }
    public let _id: String?
    public let logId: String?
    public let type: String?
    public let title: String
    public let description: String
    public let time: String?
    public let user: String?
    public let createdAt: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case _id
        case logId = "id"
        case type, title, description, time, user, createdAt, updatedAt
    }

    public var relativeTime: String {
        if let createdAt = createdAt, !createdAt.isEmpty {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var date = isoFormatter.date(from: createdAt)
            if date == nil {
                let simpleIso = ISO8601DateFormatter()
                date = simpleIso.date(from: createdAt)
            }
            if let d = date {
                let now = Date()
                let diff = max(0, Int(now.timeIntervalSince(d)))
                if diff < 60 { return "Just now" }
                let minutes = diff / 60
                if minutes < 60 { return "\(minutes) min\(minutes == 1 ? "" : "s") ago" }
                let hours = minutes / 60
                if hours < 24 { return "\(hours) hr\(hours == 1 ? "" : "s") ago" }
                let days = hours / 24
                if days < 30 { return "\(days) day\(days == 1 ? "" : "s") ago" }
                let months = days / 30
                return "\(months) mo\(months == 1 ? "" : "s") ago"
            }
        }
        return time ?? "Just now"
    }

    public var displayTime: String {
        if let createdAt = createdAt, !createdAt.isEmpty {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var date = isoFormatter.date(from: createdAt)
            if date == nil {
                let simpleIso = ISO8601DateFormatter()
                date = simpleIso.date(from: createdAt)
            }
            if let d = date {
                let out = DateFormatter()
                out.dateFormat = "hh:mm a (dd-MM-yyyy)"
                out.locale = Locale(identifier: "en_US_POSIX")
                return out.string(from: d).lowercased()
            }
        }
        return time ?? "—"
    }
}
