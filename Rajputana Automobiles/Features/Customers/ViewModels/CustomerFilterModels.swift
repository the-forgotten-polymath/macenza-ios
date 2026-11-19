import Foundation
import SwiftUI

public enum CustomerSort: String, CaseIterable, Identifiable {
    case idAsc = "ID (001, 002…)"
    case nameAsc = "Name (A → Z)"
    case nameDesc = "Name (Z → A)"
    case balanceDesc = "Highest Outstanding First"
    case balanceAsc = "Lowest Outstanding First"

    public var id: String { rawValue }

    public var chipLabel: String {
        switch self {
        case .idAsc: return "ID"
        case .nameAsc: return "Name A-Z"
        case .nameDesc: return "Name Z-A"
        case .balanceDesc: return "Highest Due"
        case .balanceAsc: return "Lowest Due"
        }
    }
}

public enum AccountStatus {
    case active, limitExceeded, inactive
}

public enum AccountStatusFilter: String, CaseIterable, Identifiable {
    case all = "All Statuses"
    case active = "Active Standing"
    case limitExceeded = "Limit Exceeded"
    case inactive = "Inactive / Dormant"

    public var id: String { rawValue }

    public var status: AccountStatus? {
        switch self {
        case .all: return nil
        case .active: return .active
        case .limitExceeded: return .limitExceeded
        case .inactive: return .inactive
        }
    }
}

public enum BalanceFilter: String, CaseIterable, Identifiable {
    case all = "All Accounts"
    case pendingDues = "Pending Dues"
    case advance = "Advance / Credit"
    case zero = "Zero Balance"

    public var id: String { rawValue }

    public var hint: String {
        switch self {
        case .all: return ""
        case .pendingDues: return "> ₹0 Due (Receivable)"
        case .advance: return "< ₹0 In Advance"
        case .zero: return "₹0.00 Nil Settled"
        }
    }
}

public enum FilterSection: String, CaseIterable, Identifiable {
    case sort = "Sort By"
    case status = "Account Status"
    case balance = "Balance"
    case groups = "Tally Groups"
    case cities = "Cities / Hubs"

    public var id: String { rawValue }
    public var title: String { rawValue }
}

public struct CustomerFilterState: Equatable {
    public var sort: CustomerSort = .nameAsc
    public var status: AccountStatusFilter = .all
    public var balance: BalanceFilter = .all
    public var groups: Set<String> = []
    public var cities: Set<String> = [] // stored in lowercase

    public init(
        sort: CustomerSort = .nameAsc,
        status: AccountStatusFilter = .all,
        balance: BalanceFilter = .all,
        groups: Set<String> = [],
        cities: Set<String> = []
    ) {
        self.sort = sort
        self.status = status
        self.balance = balance
        self.groups = groups
        self.cities = cities
    }

    public var activeCount: Int {
        var count = 0
        if sort != .nameAsc { count += 1 }
        if status != .all { count += 1 }
        if balance != .all { count += 1 }
        if !groups.isEmpty { count += 1 }
        if !cities.isEmpty { count += 1 }
        return count
    }

    public var isDefault: Bool {
        activeCount == 0
    }
}

public struct FilterOption: Identifiable, Equatable {
    public var id: String { key }
    public let key: String
    public let label: String
    public let count: Int

    public init(key: String, label: String, count: Int) {
        self.key = key
        self.label = label
        self.count = count
    }
}

public struct CustomerFilterOptions {
    public let total: Int
    public let statusCounts: [AccountStatusFilter: Int]
    public let balanceCounts: [BalanceFilter: Int]
    public let groups: [FilterOption]
    public let cities: [FilterOption]

    public static func from(customers: [Customer]) -> CustomerFilterOptions {
        // Group counts
        var groupMap: [String: Int] = [:]
        for c in customers {
            let g = c.groupKey()
            groupMap[g, default: 0] += 1
        }
        let groups = groupMap.map { FilterOption(key: $0.key, label: $0.key, count: $0.value) }
            .sorted { naturalCompare($0.label, $1.label) < 0 }

        // City counts
        var cityMap: [String: [String]] = [:]
        for c in customers {
            let key = c.cityKey()
            let rawCity = c.city?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !rawCity.isEmpty {
                cityMap[key, default: []].append(rawCity)
            } else {
                cityMap[key, default: []].append("Unknown")
            }
        }
        let cities = cityMap.map { (key, rawList) -> FilterOption in
            // Most frequent casing
            let counts = Dictionary(rawList.map { ($0, 1) }, uniquingKeysWith: +)
            let bestLabel = counts.max(by: { $0.value < $1.value })?.key ?? key.capitalized
            return FilterOption(key: key, label: bestLabel, count: rawList.count)
        }.sorted {
            if $0.count != $1.count {
                return $0.count > $1.count
            }
            return $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending
        }

        // Status counts
        var statusCounts: [AccountStatusFilter: Int] = [
            .all: customers.count,
            .active: 0,
            .limitExceeded: 0,
            .inactive: 0
        ]
        for c in customers {
            let s = c.accountStatus()
            switch s {
            case .active: statusCounts[.active, default: 0] += 1
            case .limitExceeded: statusCounts[.limitExceeded, default: 0] += 1
            case .inactive: statusCounts[.inactive, default: 0] += 1
            }
        }

        // Balance counts
        var balanceCounts: [BalanceFilter: Int] = [
            .all: customers.count,
            .pendingDues: 0,
            .advance: 0,
            .zero: 0
        ]
        for c in customers {
            let bal = c.effectiveBalance
            if bal > 0.001 {
                balanceCounts[.pendingDues, default: 0] += 1
            } else if bal < -0.001 {
                balanceCounts[.advance, default: 0] += 1
            } else {
                balanceCounts[.zero, default: 0] += 1
            }
        }

        return CustomerFilterOptions(
            total: customers.count,
            statusCounts: statusCounts,
            balanceCounts: balanceCounts,
            groups: groups,
            cities: cities
        )
    }
}

// ── Customer Extensions for Filters ──────────────────────────────
extension Customer {
    public func groupKey() -> String {
        let g = (group ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return g.isEmpty ? "Unassigned" : g
    }

    public func cityKey() -> String {
        let c = (city ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return c.isEmpty ? "unknown" : c
    }

    public func accountStatus() -> AccountStatus {
        let s = (status ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.isEmpty && s.caseInsensitiveCompare("Active") != .orderedSame {
            return .inactive
        }
        let limit = creditLimit ?? 0.0
        let bal = effectiveBalance
        if limit > 0 && abs(bal) > limit {
            return .limitExceeded
        }
        return .active
    }

    public func matchesBalance(_ filter: BalanceFilter) -> Bool {
        let bal = effectiveBalance
        switch filter {
        case .all: return true
        case .pendingDues: return bal > 0.001
        case .advance: return bal < -0.001
        case .zero: return abs(bal) <= 0.001
        }
    }

    public func matchesFilters(_ f: CustomerFilterState) -> Bool {
        if let targetStatus = f.status.status, accountStatus() != targetStatus {
            return false
        }
        if !matchesBalance(f.balance) {
            return false
        }
        if !f.groups.isEmpty && !f.groups.contains(groupKey()) {
            return false
        }
        if !f.cities.isEmpty && !f.cities.contains(cityKey()) {
            return false
        }
        return true
    }

    public func matchesSearch(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return true }
        if name.lowercased().contains(q) { return true }
        if code.lowercased().contains(q) { return true }
        if let c = city, c.lowercased().contains(q) { return true }
        if let p = phone, p.contains(q) { return true }
        if let g = gstin, g.lowercased().contains(q) { return true }
        if let t = tallyLedgerName, t.lowercased().contains(q) { return true }
        return false
    }
}

// ── Natural Compare Algorithm ───────────────────────────────────
public func naturalCompare(_ a: String, _ b: String) -> Int {
    return a.localizedStandardCompare(b).rawValue
}
