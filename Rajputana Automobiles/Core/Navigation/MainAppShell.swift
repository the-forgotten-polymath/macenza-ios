import SwiftUI

public struct MainAppShell: View {
    private var sessionManager = SessionManager.shared
    @State private var selectedTab: ManagementTab = .dashboard
    @State private var isDrawerOpen: Bool = false
    @State private var scrollTarget: String? = nil

    public enum ActiveSheet: Identifiable {
        case notifications
        case statement(party: String)
        case customerDetail(id: String)
        case orderDetail(id: String, initialOrder: OrderModel? = nil)
        case inventoryDetail(id: String)
        case staff
        case audit
        case settings
        case profile

        public var id: String {
            switch self {
            case .notifications: return "notifications"
            case .statement(let party): return "statement_\(party)"
            case .customerDetail(let id): return "customer_\(id)"
            case .orderDetail(let id, _): return "order_\(id)"
            case .inventoryDetail(let id): return "inventory_\(id)"
            case .staff: return "staff"
            case .audit: return "audit"
            case .settings: return "settings"
            case .profile: return "profile"
            }
        }
    }

    @State private var activeSheet: ActiveSheet? = nil
    @State private var showingProfile: Bool = false

    public init() {
        if let tabArg = ProcessInfo.processInfo.arguments.first(where: { $0.starts(with: "-tab:") }) {
            let tabName = tabArg.replacingOccurrences(of: "-tab:", with: "").lowercased()
            if tabName == "customers" {
                _selectedTab = State(initialValue: .customers)
            } else if tabName == "orders" {
                _selectedTab = State(initialValue: .orders)
            } else if tabName == "inventory" {
                _selectedTab = State(initialValue: .inventory)
            } else if tabName == "ledger" {
                _selectedTab = State(initialValue: .ledger)
            } else if tabName == "profile" {
                _showingProfile = State(initialValue: true)
            }
        }
        if let custArg = ProcessInfo.processInfo.arguments.first(where: { $0.starts(with: "-customerDetail:") }) {
            let id = custArg.replacingOccurrences(of: "-customerDetail:", with: "")
            _selectedTab = State(initialValue: .customers)
            _activeSheet = State(initialValue: .customerDetail(id: id))
        }
        if let ordArg = ProcessInfo.processInfo.arguments.first(where: { $0.starts(with: "-orderDetail:") }) {
            let id = ordArg.replacingOccurrences(of: "-orderDetail:", with: "")
            _selectedTab = State(initialValue: .orders)
            _activeSheet = State(initialValue: .orderDetail(id: id))
        }
        if let invArg = ProcessInfo.processInfo.arguments.first(where: { $0.starts(with: "-inventoryDetail:") }) {
            let id = invArg.replacingOccurrences(of: "-inventoryDetail:", with: "")
            _selectedTab = State(initialValue: .inventory)
            _activeSheet = State(initialValue: .inventoryDetail(id: id))
        }
        if let sheetArg = ProcessInfo.processInfo.arguments.first(where: { $0.starts(with: "-sheet:") }) {
            let sheetName = sheetArg.replacingOccurrences(of: "-sheet:", with: "")
            if sheetName == "notifications" {
                _activeSheet = State(initialValue: .notifications)
            } else if sheetName == "statement" {
                _activeSheet = State(initialValue: .statement(party: "13 Traders, Beawar"))
            } else if sheetName == "order" {
                _activeSheet = State(initialValue: .orderDetail(id: "ORD-2026-4867"))
            } else if sheetName == "staff" {
                _activeSheet = State(initialValue: .staff)
            } else if sheetName == "audit" {
                _activeSheet = State(initialValue: .audit)
            } else if sheetName == "settings" {
                _activeSheet = State(initialValue: .settings)
            } else if sheetName == "profile" {
                _showingProfile = State(initialValue: true)
            }
        }
    }

    public var body: some View {
        ZStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Top App Bar (1:1 with Android AppTopBar.kt)
                    managementTopBar

                    // Active Tab Content
                    ZStack {
                        if showingProfile {
                            UserProfileView(
                                showsTopBar: false,
                                showsBottomBar: false,
                                onOpenDrawer: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        isDrawerOpen.toggle()
                                    }
                                },
                                onOpenNotifications: {
                                    activeSheet = .notifications
                                },
                                onSignOut: {
                                    SessionManager.shared.signOut()
                                }
                            )
                        } else {
                            switch selectedTab {
                            case .dashboard:
                                NavigationStack {
                                    DashboardView(
                                        scrollTarget: scrollTarget,
                                        onNavigateToOrders: { selectedTab = .orders },
                                        onNavigateToCustomers: { selectedTab = .customers },
                                        onNavigateToInventory: { selectedTab = .inventory },
                                        onNavigateToLedger: { selectedTab = .ledger },
                                        onViewAllAuditLogs: { activeSheet = .audit }
                                    )
                                    .toolbar(.hidden, for: .navigationBar)
                                }
                            case .customers:
                                NavigationStack {
                                    CustomerListView(
                                        onSelectCustomer: { id in
                                            activeSheet = .customerDetail(id: id)
                                        },
                                        onSelectStatement: { partyName in
                                            activeSheet = .statement(party: partyName)
                                        }
                                    )
                                    .toolbar(.hidden, for: .navigationBar)
                                }
                            case .orders:
                                NavigationStack {
                                    OrderListView(
                                        onSelectOrder: { order in
                                            activeSheet = .orderDetail(id: order.targetIdForApi, initialOrder: order)
                                        }
                                    )
                                    .toolbar(.hidden, for: .navigationBar)
                                }
                            case .inventory:
                                NavigationStack {
                                    InventoryListView(
                                        onSelectItem: { id in
                                            activeSheet = .inventoryDetail(id: id)
                                        }
                                    )
                                    .toolbar(.hidden, for: .navigationBar)
                                }
                            case .ledger:
                                NavigationStack {
                                    LedgerSummaryView(
                                        onSelectParty: { partyName in
                                            activeSheet = .statement(party: partyName)
                                        }
                                    )
                                    .toolbar(.hidden, for: .navigationBar)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(Color(hex: 0xF8FAFC))

                // Bottom Navigation Bar with true Liquid Glass Translucency
                managementBottomBar
            }

            // Dimmed overlay & Sliding Side Drawer
            if isDrawerOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isDrawerOpen = false
                        }
                    }
                    .transition(.opacity)

                HStack(spacing: 0) {
                    sideDrawerContent
                        .frame(width: min(UIScreen.main.bounds.width * 0.78, 290))

                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isDrawerOpen = false
                            }
                        }
                }
                .transition(.move(edge: .leading))
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .notifications:
                NotificationListView()
            case .statement(let party):
                NavigationStack {
                    DetailedLedgerView(customerName: party, onBack: {
                        activeSheet = nil
                    })
                }
            case .customerDetail(let id):
                CustomerDetailView(
                    customerId: id,
                    canEdit: SessionManager.shared.session?.canEdit(.customers) ?? true,
                    onSelectStatement: { party in
                        activeSheet = .statement(party: party)
                    }
                )
            case .orderDetail(let id, let initialOrder):
                NavigationStack {
                    OrderDetailView(
                        orderId: id,
                        initialOrder: initialOrder,
                        canEdit: SessionManager.shared.session?.canEdit(.orders) ?? true,
                        onBack: {
                            activeSheet = nil
                        }
                    )
                }
            case .inventoryDetail(let id):
                NavigationStack {
                    InventoryDetailView(
                        itemId: id,
                        canEdit: SessionManager.shared.session?.canEdit(.inventory) ?? true,
                        onBack: {
                            activeSheet = nil
                        }
                    )
                }
            case .staff:
                NavigationStack { StaffListView() }
            case .audit:
                NavigationStack { AuditLogsView() }
            case .settings:
                NavigationStack { SettingsView() }
            case .profile:
                NavigationStack {
                    UserProfileView(
                        showsTopBar: true,
                        showsBottomBar: true,
                        onOpenDrawer: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isDrawerOpen.toggle()
                            }
                        },
                        onOpenNotifications: {
                            activeSheet = .notifications
                        },
                        onSignOut: {
                            SessionManager.shared.signOut()
                        }
                    )
                }
            }
        }
        .onAppear {
            if let tabArg = ProcessInfo.processInfo.arguments.first(where: { $0.starts(with: "-tab:") }) {
                let tabName = tabArg.replacingOccurrences(of: "-tab:", with: "").lowercased()
                if tabName == "customers" {
                    selectedTab = .customers
                } else if tabName == "orders" {
                    selectedTab = .orders
                } else if tabName == "inventory" {
                    selectedTab = .inventory
                } else if tabName == "ledger" {
                    selectedTab = .ledger
                } else if tabName == "profile" {
                    showingProfile = true
                }
            }

            if let sheetArg = ProcessInfo.processInfo.arguments.first(where: { $0.starts(with: "-sheet:") }) {
                let sheetName = sheetArg.replacingOccurrences(of: "-sheet:", with: "")
                if sheetName == "notifications" {
                    activeSheet = .notifications
                } else if sheetName == "statement" {
                    activeSheet = .statement(party: "13 Traders, Beawar")
                } else if sheetName == "order" {
                    activeSheet = .orderDetail(id: "ORD-2026-4867")
                } else if sheetName == "staff" {
                    activeSheet = .staff
                } else if sheetName == "audit" {
                    activeSheet = .audit
                } else if sheetName == "settings" {
                    activeSheet = .settings
                } else if sheetName == "profile" {
                    showingProfile = true
                } else if sheetName.starts(with: "inventory:") {
                    let id = sheetName.replacingOccurrences(of: "inventory:", with: "")
                    activeSheet = .inventoryDetail(id: id)
                }
            }

            if let scrollArg = ProcessInfo.processInfo.arguments.first(where: { $0.starts(with: "-scroll:") }) {
                scrollTarget = scrollArg.replacingOccurrences(of: "-scroll:", with: "").lowercased()
            }

            if !visibleTabs.contains(selectedTab) {
                selectedTab = visibleTabs.first ?? .dashboard
            }
        }
        .task {
            await SessionManager.shared.refreshPermissionsIfStale()
            await SessionManager.shared.refreshUnreadNotificationCount()
        }
    }

    // ── Management Top Bar (1:1 with Android AppTopBar.kt) ─────────
    private var managementTopBar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isDrawerOpen.toggle()
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Text("Rajputana Automobiles")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.black)

            Spacer()

            Button {
                activeSheet = .notifications
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(Color.black)
                        .frame(width: 44, height: 44)

                    let unread = SessionManager.shared.unreadNotificationCount
                    if unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(minWidth: 17, minHeight: 17)
                            .background(Color(hex: 0x2563EB))
                            .clipShape(Circle())
                            .offset(x: -6, y: 6)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .frame(height: 52)
        .background(Color.white.ignoresSafeArea(edges: .top))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(hex: 0xE2E8F0)),
            alignment: .bottom
        )
    }

    // ── Management Bottom Bar (Native iOS Liquid Glass Tab Bar) ─────────────
    private var visibleTabs: [ManagementTab] {
        guard let session = sessionManager.session else { return ManagementTab.allCases }
        if session.role == WorkspaceRole.superadmin {
            return ManagementTab.allCases
        }
        var tabs: [ManagementTab] = [.dashboard]
        if session.canView(Module.customers) { tabs.append(.customers) }
        if session.canView(Module.orders) { tabs.append(.orders) }
        if session.canView(Module.inventory) { tabs.append(.inventory) }
        if session.canView(Module.financials) { tabs.append(.ledger) }
        return tabs
    }

    private var managementBottomBar: some View {
        HStack(spacing: 0) {
            ForEach(visibleTabs) { tab in
                let isSelected = !showingProfile && selectedTab == tab
                Button {
                    if showingProfile || selectedTab != tab {
                        showingProfile = false
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon(isSelected: isSelected))
                            .font(.system(size: 21, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? Color(hex: 0x007AFF) : Color(hex: 0x8E8E93))
                            .frame(height: 24)
                            .scaleEffect(isSelected ? 1.06 : 1.0)

                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(isSelected ? Color(hex: 0x007AFF) : Color(hex: 0x8E8E93))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
        .background {
            ZStack {
                // 1. Hardware Ultra-Thin Optical Glass Blur
                Rectangle()
                    .fill(.ultraThinMaterial)

                // 2. Translucent Liquid Glass Sheen
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.35), location: 0.0),
                                .init(color: Color.white.opacity(0.18), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // 3. Specular Surface Reflection (Curved Glass Sheen)
                VStack {
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.40), location: 0.0),
                            .init(color: Color.white.opacity(0.10), location: 0.5),
                            .init(color: Color.clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 8)

                    Spacer()
                }

                // 4. Specular Beveled Rim Highlight (Apple Liquid Glass Top Edge)
                VStack {
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.85), location: 0.0),
                            .init(color: Color(hex: 0xCBD5E1).opacity(0.50), location: 0.35),
                            .init(color: Color.white.opacity(0.80), location: 0.70),
                            .init(color: Color(hex: 0x94A3B8).opacity(0.30), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 0.5)

                    Spacer()
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // ── Sliding Side Drawer ───────────────────────────────────
    @ViewBuilder
    private var sideDrawerContent: some View {
        VStack(spacing: 0) {
            // User Dossier Header
            if let session = SessionManager.shared.session {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image("app_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.name)
                                .font(AppTypography.headline)
                                .foregroundStyle(Color.white)
                                .lineLimit(1)

                            Text(session.role.displayName.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.brandSecondary)
                        }
                    }

                    Text(session.email)
                        .font(AppTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.navDrawerBackground)
            }

            // Drawer Items List
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(AppDrawerItem.allCases) { item in
                        if canShowItem(item) {
                            drawerRow(item: item)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .background(AppColors.cardBackground)

            Divider()

            // Sign Out Button
            Button {
                withAnimation {
                    isDrawerOpen = false
                    SessionManager.shared.signOut()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.statusRedText)

                    Text("Sign Out")
                        .font(AppTypography.subheadlineBold)
                        .foregroundStyle(AppColors.statusRedText)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .background(AppColors.cardBackground)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(AppColors.cardBackground)
        .ignoresSafeArea(edges: .vertical)
    }

    @ViewBuilder
    private func drawerRow(item: AppDrawerItem) -> some View {
        let isSelected = ManagementTab.from(drawerItem: item) == selectedTab

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isDrawerOpen = false
                if let tab = ManagementTab.from(drawerItem: item) {
                    showingProfile = false
                    selectedTab = tab
                } else {
                    switch item {
                    case .staff: activeSheet = .staff
                    case .audit: activeSheet = .audit
                    case .settings: activeSheet = .settings
                    case .profile: showingProfile = true
                    default: break
                    }
                }
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? LiquidTheme.electricBlue : AppColors.textSecondary)
                    .frame(width: 24)

                Text(item.rawValue)
                    .font(isSelected ? AppTypography.subheadlineBold : AppTypography.subheadline)
                    .foregroundStyle(isSelected ? LiquidTheme.electricBlue : AppColors.textPrimary)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(LiquidTheme.electricBlue)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? LiquidTheme.electricBlue.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func canShowItem(_ item: AppDrawerItem) -> Bool {
        guard let session = sessionManager.session else { return false }
        if session.role == WorkspaceRole.superadmin { return true }
        guard let mod = item.requiredModule else { return true }
        return session.canView(mod)
    }
}
