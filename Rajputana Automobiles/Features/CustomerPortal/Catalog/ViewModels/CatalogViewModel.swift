import Foundation
import SwiftUI

@Observable
public final class CatalogViewModel {
    public var allItems: [InventoryItem] = []
    public var searchQuery: String = ""
    public var selectedFeaturedCategory: String = "All"
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    // The 5 featured categories specifically called out in the Android app
    public let featuredCategories = [
        "All",
        "Assembly",
        "Blinkers",
        "Bosch Limited",
        "Bosch Others",
        "Damper"
    ]

    public struct CategoryPillItem: Identifiable, Hashable {
        public var id: String { name }
        public let name: String
        public let count: Int
    }

    public var categoryPills: [CategoryPillItem] {
        var counts: [String: Int] = [:]
        for item in allItems {
            let cat = (item.category ?? item.primaryGroup ?? item.stockGroup ?? "").trimmingCharacters(in: .whitespaces)
            if !cat.isEmpty {
                counts[cat, default: 0] += 1
            }
        }
        let topCats = counts.sorted { $0.value > $1.value }.prefix(12)
        return topCats.map { CategoryPillItem(name: $0.key, count: $0.value) }
    }

    public init() {}

    public var featuredProducts: [InventoryItem] {
        var list = allItems

        if selectedFeaturedCategory != "All" {
            list = list.filter {
                $0.category?.caseInsensitiveCompare(selectedFeaturedCategory) == .orderedSame ||
                $0.primaryGroup?.caseInsensitiveCompare(selectedFeaturedCategory) == .orderedSame ||
                $0.stockGroup?.caseInsensitiveCompare(selectedFeaturedCategory) == .orderedSame
            }
        }

        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.itemCode.lowercased().contains(q) ||
                $0.displayName.lowercased().contains(q) ||
                ($0.primaryGroup?.lowercased().contains(q) ?? false) ||
                ($0.category?.lowercased().contains(q) ?? false)
            }
        }

        return list
    }

    public var systemDomainHierarchy: [String: [String]] {
        var dict: [String: Set<String>] = [:]
        for item in allItems {
            let domain = item.systemDomain ?? "General"
            let cat = item.category ?? (item.primaryGroup ?? "General")
            if !cat.isEmpty {
                var currentSet = dict[domain] ?? Set<String>()
                currentSet.insert(cat)
                dict[domain] = currentSet
            }
        }
        return dict.mapValues { Array($0).sorted() }
    }

    public func loadCatalog() async {
        guard let session = SessionManager.shared.session else { return }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let fetched = try await InventoryService.shared.fetchInventory(token: session.token)
            await MainActor.run {
                self.allItems = fetched
                self.isLoading = false
                CartViewModel.shared.inventorySnapshot = fetched
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
