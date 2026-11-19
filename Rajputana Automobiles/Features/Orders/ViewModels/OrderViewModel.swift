import Foundation
import SwiftUI

public enum OrderFilterStatus: String, CaseIterable {
    case all = "All"
    case draft = "Draft"
    case confirmed = "Confirmed"
    case approved = "Approved"
    case synced = "Synced"
    case rejected = "Rejected"
}

@Observable
public final class OrderViewModel {
    public var orders: [OrderModel] = []
    public var categories: [String] = ["All Categories"]
    public var itemCategoryLookup: [String: String] = [:]

    public var selectedCategory: String = "All Categories"
    public var selectedStatus: OrderFilterStatus = .all
    public var selectedDate: Date? = nil
    public var searchQuery: String = ""

    public var isLoading: Bool = false
    public var isRefreshing: Bool = false
    public var errorMessage: String? = nil

    public init() {}

    // MARK: - Filtered Orders
    public var filteredOrders: [OrderModel] {
        return orders.filter { order in
            // 1. Category Filter
            let matchesCategory: Bool
            if selectedCategory == "All Categories" {
                matchesCategory = true
            } else {
                let items = order.items ?? []
                matchesCategory = items.contains { item in
                    let codeUpper = item.effectiveCode.uppercased()
                    let cat = itemCategoryLookup[codeUpper] ?? item.category ?? ""
                    return cat.caseInsensitiveCompare(selectedCategory) == .orderedSame
                }
            }

            // 2. Status Filter
            let matchesStatus: Bool
            if selectedStatus == .all {
                matchesStatus = true
            } else {
                matchesStatus = order.displayStatus.caseInsensitiveCompare(selectedStatus.rawValue) == .orderedSame
            }

            // 3. Date Filter (start of day matching)
            let matchesDate: Bool
            if let selDate = selectedDate {
                let cal = Calendar(identifier: .gregorian)
                if let orderDate = parseDate(order.effectiveDate) {
                    matchesDate = cal.isDate(orderDate, inSameDayAs: selDate)
                } else {
                    matchesDate = false
                }
            } else {
                matchesDate = true
            }

            // 4. Search Query Filter
            let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesSearch: Bool
            if q.isEmpty {
                matchesSearch = true
            } else {
                let numMatch = order.displayOrderNumber.lowercased().contains(q)
                let nameMatch = order.displayCustomerName.lowercased().contains(q)
                let codeMatch = order.customerCode?.lowercased().contains(q) ?? false
                let cityMatch = order.shipping?.city?.lowercased().contains(q) ?? false
                let lrMatch = order.lrNumber?.lowercased().contains(q) ?? false
                let itemMatch = order.items?.contains {
                    $0.displayName.lowercased().contains(q) || $0.effectiveCode.lowercased().contains(q)
                } ?? false

                matchesSearch = numMatch || nameMatch || codeMatch || cityMatch || lrMatch || itemMatch
            }

            return matchesCategory && matchesStatus && matchesDate && matchesSearch
        }
        .sorted { $0.effectiveDate > $1.effectiveDate }
    }

    // MARK: - Metrics
    public var totalGrossValue: Double {
        orders.reduce(0.0) { $0 + $1.effectiveAmount }
    }

    public var confirmedCount: Int {
        orders.filter { $0.displayStatus.caseInsensitiveCompare("Confirmed") == .orderedSame }.count
    }

    public var approvedCount: Int {
        orders.filter { $0.displayStatus.caseInsensitiveCompare("Approved") == .orderedSame }.count
    }

    public var grossValueCompact: String {
        compactRupees(totalGrossValue)
    }

    public var currentStatusCount: Int {
        statusCount(for: selectedStatus)
    }

    public func statusCount(for status: OrderFilterStatus) -> Int {
        if status == .all {
            return orders.count
        }
        return orders.filter { $0.displayStatus.caseInsensitiveCompare(status.rawValue) == .orderedSame }.count
    }

    public var selectedDateDisplay: String {
        guard let d = selectedDate else { return "dd-mm-yyyy" }
        let fmt = DateFormatter()
        fmt.dateFormat = "dd MMM yyyy"
        return fmt.string(from: d)
    }

    // MARK: - Data Loading
    public func loadOrders(forceRefresh: Bool = false) async {
        guard let session = SessionManager.shared.session else { return }

        await MainActor.run {
            if orders.isEmpty { self.isLoading = true }
            if forceRefresh { self.isRefreshing = true }
            self.errorMessage = nil
        }

        do {
            async let ordersTask = OrderService.shared.fetchOrders(token: session.token)
            async let inventoryTask = InventoryService.shared.fetchInventory(token: session.token)

            let (items, invItems) = try await (ordersTask, inventoryTask)

            var lookup: [String: String] = [:]
            for item in invItems {
                let code = item.itemCode.trimmingCharacters(in: .whitespaces).uppercased()
                let cat = item.category?.trimmingCharacters(in: .whitespaces) ?? ""
                if !code.isEmpty && !cat.isEmpty {
                    lookup[code] = cat
                }
            }

            let distinctCategories = Array(Set(lookup.values)).sorted()
            let allCategories = ["All Categories"] + distinctCategories

            await MainActor.run {
                self.orders = items
                self.itemCategoryLookup = lookup
                self.categories = allCategories
                self.isLoading = false
                self.isRefreshing = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.isRefreshing = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    public func updateOrderStatus(orderId: String, newStatus: String) async -> Bool {
        guard let session = SessionManager.shared.session else { return false }
        do {
            let updated = try await OrderService.shared.updateOrderStatus(token: session.token, id: orderId, status: newStatus)
            await MainActor.run {
                if let idx = self.orders.firstIndex(where: { $0.targetIdForApi == orderId || $0.orderNumber == orderId }) {
                    self.orders[idx] = updated
                }
            }
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    // MARK: - Compact INR Formatter (1:1 with Android compactRupees)
    private func compactRupees(_ amount: Double) -> String {
        let absVal = abs(amount)
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_IN")
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 6
        nf.minimumFractionDigits = 0

        if absVal < 1000 {
            let formatted = nf.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
            return "₹\(formatted)"
        }

        let scaled: Double
        let suffix: String
        if absVal >= 10_000_000 {
            scaled = amount / 10_000_000.0
            suffix = " Cr"
        } else if absVal >= 100_000 {
            scaled = amount / 100_000.0
            suffix = " L"
        } else {
            scaled = amount / 1000.0
            suffix = " K"
        }

        let formatted = nf.string(from: NSNumber(value: scaled)) ?? String(format: "%.2f", scaled)
        return "₹\(formatted)\(suffix)"
    }

    private func parseDate(_ str: String) -> Date? {
        if str.isEmpty { return nil }
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ].map { pattern -> DateFormatter in
            let df = DateFormatter()
            df.dateFormat = pattern
            df.locale = Locale(identifier: "en_US_POSIX")
            return df
        }

        for f in formatters {
            if let d = f.date(from: str) {
                return d
            }
        }
        return nil
    }
}
