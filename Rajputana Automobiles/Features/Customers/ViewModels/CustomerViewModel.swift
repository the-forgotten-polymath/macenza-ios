import Foundation
import SwiftUI

@Observable
public final class CustomerViewModel {
    public var customers: [Customer] = []
    public var searchQuery: String = ""
    public var filterState: CustomerFilterState = CustomerFilterState()
    public var visibleCount: Int = 30
    public let pageSize: Int = 30

    public var isLoading: Bool = false
    public var isRefreshing: Bool = false
    public var errorMessage: String? = nil

    public init() {}

    // ── Metric Tiles Computations (1:1 with Android exact rules) ──
    public var totalCustomers: Int {
        customers.count
    }

    public var activeVerified: Int {
        customers.count { $0.status?.caseInsensitiveCompare("Active") == .orderedSame }
    }

    public var creditLimitBreaches: Int {
        customers.count {
            let limit = $0.creditLimit ?? 0.0
            let bal = $0.effectiveBalance
            return limit > 0 && abs(bal) > limit
        }
    }

    public var totalOutstanding: Double {
        customers.reduce(0.0) { sum, c in
            let bal = c.effectiveBalance
            return bal > 0 ? sum + bal : sum
        }
    }

    public var formattedTotalOutstanding: String {
        let amount = totalOutstanding
        if amount >= 1_000_000 {
            return String(format: "₹%.1f M", amount / 1_000_000.0)
        } else if amount >= 1_000 {
            return String(format: "₹%.1f K", amount / 1_000.0)
        } else {
            return String(format: "₹%,.0f", amount)
        }
    }

    public var filterOptions: CustomerFilterOptions {
        CustomerFilterOptions.from(customers: customers)
    }

    // ── Filtered & Sorted Customer List ──────────────────────────
    public var filteredCustomers: [Customer] {
        var list = customers.filter { c in
            c.matchesSearch(searchQuery) && c.matchesFilters(filterState)
        }

        switch filterState.sort {
        case .idAsc:
            list.sort {
                let codeA = $0.code.isEmpty ? $0.id : $0.code
                let codeB = $1.code.isEmpty ? $1.id : $1.code
                return codeA.localizedStandardCompare(codeB) == .orderedAscending
            }
        case .nameAsc:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .balanceDesc:
            list.sort { $0.effectiveBalance > $1.effectiveBalance }
        case .balanceAsc:
            list.sort { $0.effectiveBalance < $1.effectiveBalance }
        }

        return list
    }

    public var pagedCustomers: [Customer] {
        let list = filteredCustomers
        return Array(list.prefix(visibleCount))
    }

    public func loadMore() {
        let total = filteredCustomers.count
        if visibleCount < total {
            visibleCount = min(total, visibleCount + pageSize)
        }
    }

    public func resetPaging() {
        visibleCount = pageSize
    }

    // ── Network Operations ─────────────────────────────────────────
    public func loadCustomers() async {
        guard let session = SessionManager.shared.session else { return }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let items = try await CustomerService.shared.fetchCustomers(token: session.token)
            await MainActor.run {
                self.customers = items
                self.visibleCount = self.pageSize
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    public func refreshCustomers() async {
        guard let session = SessionManager.shared.session else { return }

        await MainActor.run {
            self.isRefreshing = true
        }

        do {
            let items = try await CustomerService.shared.fetchCustomers(token: session.token)
            await MainActor.run {
                self.customers = items
                self.isRefreshing = false
            }
        } catch {
            await MainActor.run {
                self.isRefreshing = false
            }
        }
    }

    public func deleteCustomer(id: String) async throws {
        guard let session = SessionManager.shared.session else { return }
        try await CustomerService.shared.deleteCustomer(token: session.token, id: id)
        await MainActor.run {
            self.customers.removeAll { $0.id == id }
        }
    }
}
