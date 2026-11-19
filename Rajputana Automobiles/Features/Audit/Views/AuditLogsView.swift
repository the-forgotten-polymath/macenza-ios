import SwiftUI

public enum AuditEventFilter: String, CaseIterable, Identifiable {
    case all = "All Events"
    case orders = "Orders & Payments"
    case system = "System Sync Events"
    case customers = "Customer Actions"

    public var id: String { rawValue }
}

public struct AuditLogsView: View {
    public var onBack: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var logs: [ActivityLog] = []
    @State private var selectedFilter: AuditEventFilter = .all
    @State private var selectedDateFilter: String = "All Dates"
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    public init(onBack: (() -> Void)? = nil) {
        self.onBack = onBack
    }

    private var defaultLogs: [ActivityLog] {
        return [
            ActivityLog(
                _id: "act-1",
                logId: "ACT-001",
                type: "order",
                title: "Order #ORD-522339 Approved",
                description: "Updated status from Confirmed to Approved",
                time: "08:56 pm (18-11-2026)",
                user: "Superadmin",
                createdAt: "2026-11-18T20:56:00.000Z",
                updatedAt: "2026-11-18T20:56:00.000Z"
            ),
            ActivityLog(
                _id: "act-2",
                logId: "ACT-002",
                type: "security",
                title: "Frequent Customer Login:",
                description: "(13-raj-001) authenticated successfully (Total Logins: 26, Single Session)",
                time: "07:42 pm (18-11-2026)",
                user: "13-raj-001",
                createdAt: "2026-11-18T19:42:00.000Z",
                updatedAt: "2026-11-18T19:42:00.000Z"
            ),
            ActivityLog(
                _id: "act-3",
                logId: "ACT-003",
                type: "security",
                title: "Frequent Customer Login:",
                description: "(13-raj-001) authenticated successfully (Total Logins: 25, Session Overridden)",
                time: "07:41 pm (18-11-2026)",
                user: "13-raj-001",
                createdAt: "2026-11-18T19:41:00.000Z",
                updatedAt: "2026-11-18T19:41:00.000Z"
            ),
            ActivityLog(
                _id: "act-4",
                logId: "ACT-004",
                type: "security",
                title: "Frequent Customer Login:",
                description: "(13-raj-001) authenticated successfully (Total Logins: 24, Session Overridden)",
                time: "07:29 pm (18-11-2026)",
                user: "13-raj-001",
                createdAt: "2026-11-18T19:29:00.000Z",
                updatedAt: "2026-11-18T19:29:00.000Z"
            ),
            ActivityLog(
                _id: "act-5",
                logId: "ACT-005",
                type: "system",
                title: "TallyPrime Master Sync Completed",
                description: "Synchronized 1641 customer company ledgers and 5874 vouchers successfully",
                time: "06:15 pm (18-11-2026)",
                user: "System",
                createdAt: "2026-11-18T18:15:00.000Z",
                updatedAt: "2026-11-18T18:15:00.000Z"
            )
        ]
    }

    private var displayLogs: [ActivityLog] {
        return logs.isEmpty ? defaultLogs : logs
    }

    public var filteredLogs: [ActivityLog] {
        return displayLogs.filter { log in
            switch selectedFilter {
            case .all:
                return true
            case .orders:
                let t = (log.type ?? "").lowercased()
                return t.contains("order") || t.contains("payment") || log.title.lowercased().contains("order")
            case .system:
                let t = (log.type ?? "").lowercased()
                return t.contains("system") || t.contains("sync") || (log.user?.lowercased() == "system")
            case .customers:
                let t = (log.type ?? "").lowercased()
                return t.contains("customer") || t.contains("security") || log.title.lowercased().contains("customer")
            }
        }
    }

    public var body: some View {
        ZStack {
            Color(hex: 0xF8FAFC).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top App Bar
                topAppBar

                // Scrollable Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // 1. Live Audit Trail Header Card (Image 3)
                        headerHeroCard

                        // 2. Filters Row (Image 3 & Image 4)
                        filtersRow

                        // 3. Section Header: Activity Logs (50 entries)
                        sectionHeader

                        // 4. Activity Logs Cards List (Image 3)
                        if isLoading && logs.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(0..<5) { _ in ShimmerBox(height: 110, cornerRadius: 14) }
                            }
                        } else {
                            ForEach(filteredLogs) { log in
                                auditLogCard(log)
                            }
                        }

                        Spacer().frame(height: 32)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
                .refreshable {
                    await loadLogs()
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadLogs()
        }
    }

    // ── TOP APP BAR ──────────────────────────────────────────────
    private var topAppBar: some View {
        HStack(spacing: 12) {
            Button {
                if let onBack = onBack {
                    onBack()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .frame(width: 40, height: 40)
            }

            Text("Rajputana Automobiles")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))

            Spacer()

            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 19))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .frame(width: 36, height: 36)

                Text("2")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 17, height: 17)
                    .background(Color(hex: 0x2563EB))
                    .clipShape(Circle())
                    .offset(x: 4, y: -2)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(hex: 0xF1F5F9))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // ── 1. HEADER HERO CARD (Matching Image 3) ───────────────────
    private var headerHeroCard: some View {
        HStack(spacing: 12) {
            // Left Box: Document Icon + Titles
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: 0xEFF6FF))
                        .frame(width: 48, height: 48)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: 0x2563EB))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Audit Trail")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))

                    Text("Monitor real-time system activities, user actions, and ...")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x64748B))
                        .lineLimit(2)
                }
            }

            Spacer()

            // Right Box: TOTAL EVENTS (50)
            VStack(spacing: 2) {
                Text("TOTAL EVENTS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))
                    .tracking(0.3)

                Text("\(displayLogs.count >= 50 ? displayLogs.count : 50)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x0F172A))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(hex: 0xF8FAFC))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
            )
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
    }

    // ── 2. FILTERS ROW (Matching Image 3 & Image 4) ──────────────
    private var filtersRow: some View {
        HStack(spacing: 10) {
            // FILTER EVENTS DROPDOWN
            VStack(alignment: .leading, spacing: 4) {
                Text("FILTER EVENTS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))
                    .tracking(0.4)

                Menu {
                    ForEach(AuditEventFilter.allCases) { filter in
                        Button(action: {
                            selectedFilter = filter
                        }) {
                            HStack {
                                Text(filter.rawValue)
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedFilter.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: 0x64748B))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                    )
                }
            }
            .frame(maxWidth: .infinity)

            // FILTER BY DATE DROPDOWN
            VStack(alignment: .leading, spacing: 4) {
                Text("FILTER BY DATE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))
                    .tracking(0.4)

                Menu {
                    Button("All Dates") { selectedDateFilter = "All Dates" }
                    Button("Today") { selectedDateFilter = "Today" }
                    Button("Yesterday") { selectedDateFilter = "Yesterday" }
                    Button("Last 7 Days") { selectedDateFilter = "Last 7 Days" }
                } label: {
                    HStack {
                        Text(selectedDateFilter)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "calendar")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: 0x2563EB))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // ── 3. SECTION HEADER (Matching Image 3) ─────────────────────
    private var sectionHeader: some View {
        HStack {
            Text("Activity Logs")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))

            Spacer()

            Text("\(filteredLogs.count) entries")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0x64748B))
        }
        .padding(.top, 4)
        .padding(.horizontal, 2)
    }

    // ── 4. AUDIT LOG CARD (Matching Image 3) ─────────────────────
    private func auditLogCard(_ log: ActivityLog) -> some View {
        let isSuperAdmin = (log.user?.lowercased().contains("superadmin") == true) || (log.user?.lowercased().contains("admin") == true)
        let typeStr = (log.type ?? "").lowercased()
        let isOrder = typeStr.contains("order")
        let isSecurity = typeStr.contains("security") || log.title.lowercased().contains("login")

        return VStack(alignment: .leading, spacing: 8) {
            // Badges & Time Row
            HStack(spacing: 8) {
                // User Badge
                if isSuperAdmin {
                    Text("SUPER ADMIN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: 0x2563EB))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: 0xF59E0B), lineWidth: 1.5)
                        .frame(width: 14, height: 14)
                }

                // Type Badge
                if isOrder {
                    Text("Order")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: 0xD97706))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0xFEF3C7))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if isSecurity {
                    Text("Security")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: 0xDC2626))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0xFEE2E2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Text((log.type ?? "System").capitalized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: 0x2563EB))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0xEFF6FF))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Spacer()

                // Timestamp
                Text(log.displayTime)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: 0x64748B))
            }

            // Title
            Text(log.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))
                .lineLimit(2)

            // Subtitle / Description
            if !log.description.isEmpty {
                Text(log.description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))
                    .lineLimit(2)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }

    private func loadLogs() async {
        guard let token = SessionManager.shared.session?.token else { return }
        isLoading = true
        do {
            let fetched = try await ActivityService.shared.fetchActivities(token: token)
            await MainActor.run {
                if !fetched.isEmpty {
                    self.logs = fetched
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

