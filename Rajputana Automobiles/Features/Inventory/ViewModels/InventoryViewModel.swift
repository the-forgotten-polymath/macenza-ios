import Foundation
import SwiftUI

public enum InventorySort: String, CaseIterable, Identifiable {
    case stockHighToLow = "Stock: High to Low"
    case stockLowToHigh = "Stock: Low to High"
    case priceHighToLow = "Price: High to Low"
    case priceLowToHigh = "Price: Low to High"
    case nameAToZ = "Name: A to Z"
    case valueHighToLow = "Value: High to Low"

    public var id: String { rawValue }
    public var label: String { rawValue }
}

@Observable
public final class InventoryViewModel {
    public var items: [InventoryItem] = []
    public var searchQuery: String = ""
    public var selectedTopGroup: String? = nil
    public var selectedCategories: Set<String> = []
    public var minPrice: String = ""
    public var maxPrice: String = ""
    public var onlyZeroPrice: Bool = false
    public var selectedSort: InventorySort = .nameAToZ
    public var visibleCount: Int = 30

    public var isLoading: Bool = false
    public var isSyncingTally: Bool = false
    public var tallySyncMessage: String? = nil
    public var errorMessage: String? = nil

    public init() {}

    // Grouping for top horizontal chips: "All", "Bosch Chassis...", etc.
    public var topGroupsWithCounts: [(label: String, count: Int)] {
        var counts: [String: Int] = [:]
        for item in items {
            let grp = item.inventoryTopGroup
            counts[grp, default: 0] += 1
        }
        let sorted = counts.sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
        return [("All", items.count)] + sorted.map { ($0.key, $0.value) }
    }

    // Category counts for the filter sheet
    public var categoryCounts: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for item in items {
            let cat = item.inventoryCategory
            counts[cat, default: 0] += 1
        }
        return counts.sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }.map { ($0.key, $0.value) }
    }

    public var activeFilterCount: Int {
        var count = 0
        if selectedSort != .nameAToZ { count += 1 }
        if !selectedCategories.isEmpty { count += 1 }
        if !minPrice.trimmingCharacters(in: .whitespaces).isEmpty ||
           !maxPrice.trimmingCharacters(in: .whitespaces).isEmpty ||
           onlyZeroPrice {
            count += 1
        }
        return count
    }

    public var filteredItems: [InventoryItem] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let minP = Double(minPrice.trimmingCharacters(in: .whitespaces))
        let maxP = Double(maxPrice.trimmingCharacters(in: .whitespaces))

        var list = items

        // Top group chip filter
        if let topGroup = selectedTopGroup, topGroup != "All" {
            list = list.filter { $0.inventoryTopGroup == topGroup }
        }

        // Category multi-select
        if !selectedCategories.isEmpty {
            list = list.filter { selectedCategories.contains($0.inventoryCategory) }
        }

        // Search text
        if !q.isEmpty {
            list = list.filter {
                $0.itemCode.lowercased().contains(q) ||
                $0.displayName.lowercased().contains(q) ||
                ($0.productName?.lowercased().contains(q) ?? false) ||
                ($0.itemName?.lowercased().contains(q) ?? false)
            }
        }

        // Price filtering
        if onlyZeroPrice {
            list = list.filter { ($0.unitPrice ?? 0.0) <= 0.0 }
        } else {
            if let minVal = minP {
                list = list.filter { ($0.unitPrice ?? 0.0) >= minVal }
            }
            if let maxVal = maxP {
                list = list.filter { ($0.unitPrice ?? 0.0) <= maxVal }
            }
        }

        // Sorting
        switch selectedSort {
        case .stockHighToLow:
            list.sort { ($0.stockLevel ?? 0.0) > ($1.stockLevel ?? 0.0) }
        case .stockLowToHigh:
            list.sort { ($0.stockLevel ?? 0.0) < ($1.stockLevel ?? 0.0) }
        case .priceHighToLow:
            list.sort { ($0.unitPrice ?? 0.0) > ($1.unitPrice ?? 0.0) }
        case .priceLowToHigh:
            list.sort { ($0.unitPrice ?? 0.0) < ($1.unitPrice ?? 0.0) }
        case .nameAToZ:
            list.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        case .valueHighToLow:
            list.sort { ($0.closingValue ?? 0.0) > ($1.closingValue ?? 0.0) }
        }

        return list
    }

    public var visibleItems: [InventoryItem] {
        Array(filteredItems.prefix(visibleCount))
    }

    public var hasMore: Bool {
        visibleCount < filteredItems.count
    }

    public func loadMore() {
        if hasMore {
            visibleCount += 30
        }
    }

    public func resetFilters() {
        selectedSort = .nameAToZ
        selectedCategories = []
        minPrice = ""
        maxPrice = ""
        onlyZeroPrice = false
    }

    public func loadInventory(forceRefresh: Bool = false) async {
        guard let session = SessionManager.shared.session else { return }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let fetched = try await InventoryService.shared.fetchInventory(token: session.token, forceRefresh: forceRefresh)
            await MainActor.run {
                self.items = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    public func deleteItem(id: String) async -> Bool {
        guard let session = SessionManager.shared.session else { return false }
        do {
            try await InventoryService.shared.deleteItem(token: session.token, id: id)
            await MainActor.run {
                self.items.removeAll { $0.id == id }
            }
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    public func syncWithTally() async {
        guard let session = SessionManager.shared.session else { return }

        await MainActor.run {
            self.isSyncingTally = true
            self.tallySyncMessage = nil
        }

        do {
            let res = try await InventoryService.shared.syncTally(token: session.token)
            await MainActor.run {
                self.isSyncingTally = false
                self.tallySyncMessage = res.message ?? "Tally stock synchronized successfully!"
            }
            await loadInventory(forceRefresh: true)
        } catch {
            await MainActor.run {
                self.isSyncingTally = false
                self.errorMessage = "Tally sync failed: \(error.localizedDescription)"
            }
        }
    }
}

// Helpers on InventoryItem
extension InventoryItem {
    public var inventoryTopGroup: String {
        let p = (primaryGroup ?? "").trimmingCharacters(in: .whitespaces)
        return p.isEmpty ? "Ungrouped" : p
    }

    public var inventoryCategory: String {
        let s = (stockGroup ?? "").trimmingCharacters(in: .whitespaces)
        if !s.isEmpty { return s }
        let c = (category ?? "").trimmingCharacters(in: .whitespaces)
        if !c.isEmpty { return c }
        return "Uncategorized"
    }

    public var stockLevelDisplay: String {
        if let s = stockLevel {
            return s.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(s))" : String(format: "%.1f", s)
        }
        return "0"
    }

    public var isOutOfStock: Bool {
        (stockLevel ?? 0.0) <= 0.0
    }
}
