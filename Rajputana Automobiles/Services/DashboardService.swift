import Foundation
import SwiftUI

public struct DashboardAggregatedData {
    public let monthlySalesAmount: Double
    public let monthlySalesTarget: Double
    public let monthlySalesChangePercent: Double

    public let totalOutstanding: Double
    public let agingSegments: [AgingChartSegment]

    public let activeCustomersCount: Int
    public let warehouseStockUnits: Double
    public let warehouseSkuCount: Int

    public let salesTrends: [GrossSalesPoint]
    public let recentActivities: [ActivityLog]
}

public final class DashboardService {
    public static let shared = DashboardService()
    private let network = NetworkService.shared

    private init() {}

    public func fetchDashboardBundle(token: String, canViewAuditLogs: Bool) async throws -> DashboardAggregatedData {
        // Parallel execution of the 5 core endpoints
        async let paymentDueTask: PaymentDueResponse = network.request(APIEndpoint(path: "api/ledger/payment-due"), token: token)
        async let ordersTask: [OrderModel] = network.request(APIEndpoint(path: "api/orders"), token: token)
        async let customersTask: [Customer] = network.request(APIEndpoint(path: "api/customers"), token: token)
        async let inventoryTask: [InventoryItem] = network.request(APIEndpoint(path: "api/inventory"), token: token)
        async let invoicesTask: [Invoice] = network.request(APIEndpoint(path: "api/ledger/invoices"), token: token)

        let (paymentDue, orders, customers, inventory, invoices) = try await (
            paymentDueTask,
            ordersTask,
            customersTask,
            inventoryTask,
            invoicesTask
        )

        // Conditionally fetch audit logs
        var activities: [ActivityLog] = []
        if canViewAuditLogs {
            let activityEndpoint = APIEndpoint(path: "api/activities")
            activities = (try? await network.request(activityEndpoint, token: token)) ?? []
        }

        // Heavy calculation executed on background priority
        return try await Task.detached(priority: .userInitiated) {
            return DashboardService.calculateMetrics(
                paymentDue: paymentDue,
                orders: orders,
                customers: customers,
                inventory: inventory,
                invoices: invoices,
                activities: activities
            )
        }.value
    }

    private static func calculateMetrics(
        paymentDue: PaymentDueResponse,
        orders: [OrderModel],
        customers: [Customer],
        inventory: [InventoryItem],
        invoices: [Invoice],
        activities: [ActivityLog]
    ) -> DashboardAggregatedData {
        let calendar = Calendar.current
        let now = Date()

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"

        let currentMonthKey = monthFormatter.string(from: now)

        let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let previousMonthKey = monthFormatter.string(from: previousMonthDate)

        // 1. Monthly Sales KPI (Approved orders in current month)
        let approvedOrders = orders.filter {
            $0.displayStatus.caseInsensitiveCompare("Approved") == .orderedSame ||
            $0.displayStatus.caseInsensitiveCompare("Synced") == .orderedSame ||
            $0.displayStatus.caseInsensitiveCompare("Dispatched") == .orderedSame ||
            $0.displayStatus.caseInsensitiveCompare("Delivered") == .orderedSame
        }

        var thisMonthApprovedSales = 0.0
        var lastMonthApprovedSales = 0.0

        for order in approvedOrders {
            let dateStr = order.effectiveDate
            if dateStr.contains(currentMonthKey) {
                thisMonthApprovedSales += order.effectiveAmount
            } else if dateStr.contains(previousMonthKey) {
                lastMonthApprovedSales += order.effectiveAmount
            }
        }

        // Target derived from previous month invoice revenue * 1.10
        var lastMonthInvoiceRevenue = 0.0
        for invoice in invoices {
            if let date = invoice.date, date.contains(previousMonthKey) {
                lastMonthInvoiceRevenue += invoice.effectiveAmount
            }
        }
        let monthlyTarget = (lastMonthInvoiceRevenue > 0 ? lastMonthInvoiceRevenue : 5_000_000.0) * 1.10

        let salesChange = lastMonthApprovedSales > 0
            ? ((thisMonthApprovedSales - lastMonthApprovedSales) / lastMonthApprovedSales) * 100.0
            : 0.0

        // 2. Aging Pie Segments
        let totalOut = paymentDue.totalOutstanding > 0 ? paymentDue.totalOutstanding : 1.0
        let b1 = paymentDue.zeroToThirtyDays
        let b2 = paymentDue.thirtyOneToSixtyDays
        let b3 = paymentDue.sixtyPlusDays

        let agingSegments = [
            AgingChartSegment(label: "0–30 Days", amount: b1.amount, percentage: (b1.amount / totalOut) * 100.0, count: b1.count, color: AppColors.agingCurrent),
            AgingChartSegment(label: "31–60 Days", amount: b2.amount, percentage: (b2.amount / totalOut) * 100.0, count: b2.count, color: AppColors.agingDueSoon),
            AgingChartSegment(label: "60+ Days", amount: b3.amount, percentage: (b3.amount / totalOut) * 100.0, count: b3.count, color: AppColors.agingOverdue)
        ]

        // 3. Warehouse Stock
        let totalUnits = inventory.reduce(0.0) { $0 + $1.effectiveStock }
        let totalSkus = inventory.count

        // 4. Gross Sales Trends: Rolling 7 Months
        var rollingMonths: [Date] = []
        for offset in (0..<7).reversed() {
            if let mDate = calendar.date(byAdding: .month, value: -offset, to: now) {
                rollingMonths.append(mDate)
            }
        }

        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "MMM"

        var trends: [GrossSalesPoint] = []
        for mDate in rollingMonths {
            let key = monthFormatter.string(from: mDate)
            let label = labelFormatter.string(from: mDate)

            var monthRevenue = 0.0
            for invoice in invoices {
                if let d = invoice.date, d.contains(key) {
                    monthRevenue += invoice.effectiveAmount
                }
            }

            // Fallback to approved orders if invoice data for running month is not generated yet
            if monthRevenue == 0 {
                for order in approvedOrders {
                    if order.effectiveDate.contains(key) {
                        monthRevenue += order.effectiveAmount
                    }
                }
            }

            let target = monthRevenue * 1.10
            let revLakhs = min(150.0, monthRevenue / 100_000.0)
            let targetLakhs = min(150.0, target / 100_000.0)

            trends.append(GrossSalesPoint(
                monthKey: key,
                monthLabel: label,
                revenueInLakhs: revLakhs,
                targetInLakhs: targetLakhs,
                rawRevenue: monthRevenue,
                rawTarget: target
            ))
        }

        return DashboardAggregatedData(
            monthlySalesAmount: thisMonthApprovedSales,
            monthlySalesTarget: monthlyTarget,
            monthlySalesChangePercent: salesChange,
            totalOutstanding: paymentDue.totalOutstanding,
            agingSegments: agingSegments,
            activeCustomersCount: customers.count,
            warehouseStockUnits: totalUnits,
            warehouseSkuCount: totalSkus,
            salesTrends: trends,
            recentActivities: Array(activities.prefix(5))
        )
    }
}
