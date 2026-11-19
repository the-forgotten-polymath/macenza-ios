import SwiftUI

public struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    public var scrollTarget: String? = nil

    public var onNavigateToOrders: (() -> Void)? = nil
    public var onNavigateToCustomers: (() -> Void)? = nil
    public var onNavigateToInventory: (() -> Void)? = nil
    public var onNavigateToLedger: (() -> Void)? = nil
    public var onViewAllAuditLogs: (() -> Void)? = nil

    public init(
        scrollTarget: String? = nil,
        onNavigateToOrders: (() -> Void)? = nil,
        onNavigateToCustomers: (() -> Void)? = nil,
        onNavigateToInventory: (() -> Void)? = nil,
        onNavigateToLedger: (() -> Void)? = nil,
        onViewAllAuditLogs: (() -> Void)? = nil
    ) {
        self.scrollTarget = scrollTarget
        self.onNavigateToOrders = onNavigateToOrders
        self.onNavigateToCustomers = onNavigateToCustomers
        self.onNavigateToInventory = onNavigateToInventory
        self.onNavigateToLedger = onNavigateToLedger
        self.onViewAllAuditLogs = onViewAllAuditLogs
    }

    public var body: some View {
        ZStack {
            Color(hex: 0xF8FAFC).ignoresSafeArea()

            if viewModel.isLoading && viewModel.data == nil {
                loadingSkeleton
            } else {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            // 1. Dashboard Overview Card
                            dashboardOverviewCard
                                .id("overview")
                                .padding(.bottom, 24)

                            // 2. Executive Summary Header
                            sectionHeader(title: "EXECUTIVE SUMMARY", trailing: "Live Telemetry")
                                .id("summary")
                                .padding(.bottom, 14)

                            // 3. 2x2 Metric Cards Grid
                            if let d = viewModel.data {
                                metricsGrid(d)
                                    .padding(.bottom, 24)

                                // 4. Sales & Receivables Analytics Header
                                sectionHeader(title: "SALES & RECEIVABLES ANALYTICS", trailing: nil)
                                    .padding(.bottom, 14)

                                // 5. Gross Sales Trends Card
                                GrossSalesChartView(data: d.salesTrends)
                                    .id("sales")
                                    .padding(.bottom, 24)

                                // 6. Outstanding Aging Analysis Card
                                AgingPieChartView(segments: d.agingSegments, totalOutstanding: d.totalOutstanding)
                                    .id("aging")
                                    .padding(.bottom, 24)

                                // 7. Recent System Activity Section
                                if SessionManager.shared.session?.canView(.auditLogs) ?? true {
                                    recentSystemActivitySection(d.recentActivities)
                                        .id("activity")
                                        .padding(.bottom, 24)
                                }
                            }

                            Spacer().frame(height: 32)
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                    }
                    .refreshable {
                        await viewModel.loadDashboard()
                    }
                    .onAppear {
                        if let target = scrollTarget, viewModel.data != nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    proxy.scrollTo(target, anchor: .top)
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.data != nil) { hasData in
                        if hasData, let target = scrollTarget {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    proxy.scrollTo(target, anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
    }

    // ── 1. DASHBOARD OVERVIEW CARD ────────────────────────────────
    private var dashboardOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Dashboard Overview")
                .font(.system(size: 21, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))

            Text("Real-time financial metrics, distributor receivables, ledger compliance, and warehouse inventory control.")
                .font(.system(size: 13, weight: .regular))
                .lineSpacing(4)
                .foregroundColor(Color(hex: 0x64748B))

            VStack(alignment: .leading, spacing: 8) {
                overviewChip(icon: "checkmark.seal", title: "100% Genuine Spares")
                overviewChip(icon: "shippingbox", title: "Multi-Warehouse Catalog")
                overviewChip(icon: "truck.box", title: "Fast Dispatch Pipeline")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xF1F5F9), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }

    private func overviewChip(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: 0x2F6BDE))
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: 0x475569))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
    }

    // ── SECTION HEADER ────────────────────────────────────────────
    private func sectionHeader(title: String, trailing: String?) -> some View {
        HStack(alignment: .center, spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: 0x2563EB))
                .frame(width: 5, height: 16)

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: 0x1E293B))
                .tracking(0.3)

            Spacer()

            if let tr = trailing {
                Text(tr)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: 0x64748B))
            }
        }
    }

    // ── 2. METRICS 2x2 GRID ───────────────────────────────────────
    private func metricsGrid(_ d: DashboardAggregatedData) -> some View {
        let salesFormatted = formatCurrencyCompact(d.monthlySalesAmount)
        let salesChange = formatChangePercent(d.monthlySalesChangePercent)
        let salesTarget = "Target \(formatCurrencyCompact(d.monthlySalesTarget))"

        let outstandingFormatted = formatCurrencyCompact(d.totalOutstanding)
        let customersFormatted = "\(d.activeCustomersCount)"

        let stockUnits = formatUnits(d.warehouseStockUnits)
        let stockChange = "\(d.warehouseSkuCount) SKUs"

        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                // Card 1: Monthly Sales
                metricCard(
                    title: "MONTHLY SALES",
                    value: salesFormatted,
                    symbol: "₹",
                    isSystemSymbol: false,
                    changeText: salesChange,
                    footerText: salesTarget,
                    onTap: { onNavigateToOrders?() }
                )

                // Card 2: Outstanding Balance
                metricCard(
                    title: "OUTSTANDING BALANCE",
                    value: outstandingFormatted,
                    symbol: "building.columns",
                    isSystemSymbol: true,
                    changeText: "Live",
                    footerText: "Pending collection",
                    onTap: { onNavigateToLedger?() }
                )
            }

            HStack(spacing: 10) {
                // Card 3: Active Customers
                metricCard(
                    title: "ACTIVE CUSTOMERS",
                    value: customersFormatted,
                    symbol: "person.2",
                    isSystemSymbol: true,
                    changeText: "Synced",
                    footerText: "Verified network",
                    onTap: { onNavigateToCustomers?() }
                )

                // Card 4: Warehouse Stock
                metricCard(
                    title: "WAREHOUSE STOCK",
                    value: stockUnits,
                    symbol: "shippingbox",
                    isSystemSymbol: true,
                    changeText: stockChange,
                    footerText: "Active SKUs",
                    onTap: { onNavigateToInventory?() }
                )
            }
        }
    }

    private func metricCard(
        title: String,
        value: String,
        symbol: String,
        isSystemSymbol: Bool,
        changeText: String,
        footerText: String,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Text(title)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(Color(hex: 0x64748B))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color(hex: 0xF8FAFC))
                            .frame(width: 30, height: 30)

                        if isSystemSymbol {
                            Image(systemName: symbol)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: 0x0F172A))
                        } else {
                            Text(symbol)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: 0x0F172A))
                        }
                    }
                }

                Text(value)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Divider()
                    .background(Color(hex: 0xF1F5F9))

                HStack(alignment: .center) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: 0x059669))
                        Text(changeText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: 0x059669))
                    }

                    Spacer()

                    Text(footerText)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .lineLimit(1)
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xF1F5F9), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // ── 7. RECENT SYSTEM ACTIVITY SECTION ─────────────────────────
    private func recentSystemActivitySection(_ activities: [ActivityLog]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "RECENT SYSTEM ACTIVITY", trailing: "Real-Time")

            if activities.isEmpty {
                VStack {
                    Text("No recent activity yet.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: 0x64748B))
                        .padding(20)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 10) {
                    ForEach(activities) { log in
                        activityCard(log)
                    }
                }

                // View All Audit Logs Button
                Button(action: { onViewAllAuditLogs?() }) {
                    Text("View All Audit Logs →")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: 0x2563EB))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
        }
    }

    private func activityCard(_ log: ActivityLog) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(log.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .lineLimit(1)

                Spacer()

                Text(log.relativeTime)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: 0x94A3B8))
            }

            Text(log.description)
                .font(.system(size: 12, weight: .regular))
                .lineSpacing(2)
                .foregroundColor(Color(hex: 0x64748B))
                .lineLimit(2)

            Text("by \(log.user ?? "Admin")")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(hex: 0x94A3B8))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xF1F5F9), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }

    // ── LOADING SKELETON ──────────────────────────────────────────
    private var loadingSkeleton: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ShimmerBox(height: 140, cornerRadius: 16)
                HStack(spacing: 10) {
                    ShimmerBox(height: 120, cornerRadius: 14)
                    ShimmerBox(height: 120, cornerRadius: 14)
                }
                HStack(spacing: 10) {
                    ShimmerBox(height: 120, cornerRadius: 14)
                    ShimmerBox(height: 120, cornerRadius: 14)
                }
                ShimmerBox(height: 240, cornerRadius: 16)
                ShimmerBox(height: 320, cornerRadius: 16)
            }
            .padding(14)
        }
    }

    // ── FORMATTING HELPERS ────────────────────────────────────────
    private func formatCurrencyCompact(_ amount: Double) -> String {
        let absVal = abs(amount)
        if absVal >= 10_000_000 {
            return String(format: "₹%.2f Cr", amount / 10_000_000)
        } else if absVal >= 100_000 {
            return String(format: "₹%.2f L", amount / 100_000)
        } else if absVal >= 1_000 {
            return String(format: "₹%.1f K", amount / 1_000)
        } else {
            return String(format: "₹%.0f", amount)
        }
    }

    private func formatUnits(_ units: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.locale = Locale(identifier: "en_IN")
        fmt.maximumFractionDigits = 1
        fmt.minimumFractionDigits = 0
        let s = fmt.string(from: NSNumber(value: units)) ?? "\(units)"
        return "\(s) Units"
    }

    private func formatChangePercent(_ pct: Double) -> String {
        let sign = pct >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, pct)
    }
}
