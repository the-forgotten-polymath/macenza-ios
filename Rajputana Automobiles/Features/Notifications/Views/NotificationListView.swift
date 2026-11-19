import SwiftUI

public struct NotificationListView: View {
    @State private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss

    public var onNavigateToOrder: ((String) -> Void)? = nil
    public var onNavigateToCustomer: ((String) -> Void)? = nil

    public struct ProfileSheetItem: Identifiable {
        public let id: String
        public init(id: String) { self.id = id }
    }

    public struct OrderSheetItem: Identifiable {
        public let id: String
        public init(id: String) { self.id = id }
    }

    @State private var activeProfileItem: ProfileSheetItem? = nil
    @State private var activeOrderItem: OrderSheetItem? = nil

    public init(
        onNavigateToOrder: ((String) -> Void)? = nil,
        onNavigateToCustomer: ((String) -> Void)? = nil
    ) {
        self.onNavigateToOrder = onNavigateToOrder
        self.onNavigateToCustomer = onNavigateToCustomer
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: 0xF4F6F9).ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── TOP BAR (Matching Image 8) ───────────────
                    topBar

                    // ── SCROLLABLE NOTIFICATIONS CONTENT ──────────
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            // 1. Search Bar
                            searchBar
                                .padding(.horizontal, 14)
                                .padding(.top, 10)

                            // 2. Horizontal Filter Chips
                            filterChipsRow
                                .padding(.top, 4)

                            // 3. Notification Cards List
                            if viewModel.isLoading && viewModel.notifications.isEmpty {
                                ForEach(0..<5, id: \.self) { _ in
                                    ShimmerBox(height: 140, cornerRadius: 16)
                                        .padding(.horizontal, 14)
                                }
                            } else if viewModel.filteredNotifications.isEmpty {
                                emptyState
                            } else {
                                ForEach(viewModel.filteredNotifications) { item in
                                    notificationCard(item)
                                        .padding(.horizontal, 14)
                                }
                            }

                            Spacer().frame(height: 40)
                        }
                    }
                    .refreshable {
                        await viewModel.loadNotifications()
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadNotifications()
            }
            .sheet(item: $activeProfileItem) { item in
                CustomerDetailView(
                    customerId: item.id,
                    canEdit: SessionManager.shared.session?.canEdit(.customers) ?? true
                )
            }
            .sheet(item: $activeOrderItem) { item in
                NavigationStack {
                    OrderDetailView(
                        orderId: item.id,
                        canEdit: SessionManager.shared.session?.canEdit(.orders) ?? true
                    )
                }
            }
        }
    }

    // ── TOP APP BAR ──────────────────────────────────────────────
    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Text("Notifications")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))

            if viewModel.unreadCount > 0 {
                Text("\(viewModel.unreadCount) Unread")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: 0xDC2626))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: 0xFEE2E2))
                    .clipShape(Capsule())
            }

            Spacer()

            Button(action: {
                Task { await viewModel.markAllAsRead() }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Mark All")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Color(hex: 0x2563EB))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: 0xEFF6FF))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 54)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(hex: 0xE2E8F0))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // ── SEARCH BAR ───────────────────────────────────────────────
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: 0x94A3B8))

            TextField("Search notifications or SKU...", text: $viewModel.searchQuery)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: 0x0F172A))
                .autocorrectionDisabled()

            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: 0x94A3B8))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── FILTER CHIPS ROW ─────────────────────────────────────────
    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    let isSelected = viewModel.selectedFilter == filter
                    let label: String = {
                        switch filter {
                        case .all:
                            return "All (\(viewModel.notifications.count))"
                        case .unread:
                            return "Unread (\(viewModel.unreadCount))"
                        case .orders:
                            return "Orders (\(viewModel.ordersCount))"
                        case .security:
                            return "Security Logins"
                        }
                    }()

                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            viewModel.selectedFilter = filter
                        }
                    }) {
                        Text(label)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(isSelected ? Color(hex: 0x2563EB) : Color.white)
                            .foregroundColor(isSelected ? .white : Color(hex: 0x475569))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : Color(hex: 0xE2E8F0), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
        }
    }

    // ── NOTIFICATION CARD ────────────────────────────────────────
    private func notificationCard(_ item: NotificationItem) -> some View {
        let isLoginAlert = item.isSecurityAlert
        let isUnread = !item.read

        return VStack(alignment: .leading, spacing: 0) {
            // Header: Icon + Title + Timestamp
            HStack(alignment: .top, spacing: 12) {
                // Circle Icon
                ZStack {
                    Circle()
                        .fill(isLoginAlert ? Color(hex: 0xFEF3C7) : Color(hex: 0xEFF6FF))
                        .frame(width: 40, height: 40)

                    Image(systemName: isLoginAlert ? "exclamationmark.triangle" : "bag.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isLoginAlert ? Color(hex: 0xD97706) : Color(hex: 0x2563EB))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)

                        if isUnread {
                            Circle()
                                .fill(Color(hex: 0x2563EB))
                                .frame(width: 8, height: 8)
                        }

                        Spacer()

                        Text(item.effectiveTimestamp.isEmpty ? "Today" : item.effectiveTimestamp)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: 0x94A3B8))
                    }

                    Text(item.message)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: 0x475569))
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            // Content Area (Login details or Order details)
            if isLoginAlert {
                loginAlertBox(item)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
            } else if item.isOrderNotification {
                orderNotificationBox(item)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
            }

            // Divider
            Rectangle()
                .fill(Color(hex: 0xF1F5F9))
                .frame(height: 1)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Bottom Actions Row (Matching Image 8)
            HStack(spacing: 12) {
                Button(action: {
                    if isLoginAlert {
                        let targetCustId = item.effectiveCustomerIdentifier
                        if let onNavigateToCustomer = onNavigateToCustomer {
                            onNavigateToCustomer(targetCustId)
                        } else {
                            activeProfileItem = ProfileSheetItem(id: targetCustId)
                        }
                    } else {
                        let ordId = item.orderData?.orderId ?? item.orderData?.orderNumber ?? "ORD-522339"
                        if let onNavigateToOrder = onNavigateToOrder {
                            onNavigateToOrder(ordId)
                        } else {
                            activeOrderItem = OrderSheetItem(id: ordId)
                        }
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: isLoginAlert ? "arrow.up.forward.square" : "eye")
                            .font(.system(size: 14, weight: .semibold))
                        Text(isLoginAlert ? "View Profile" : "View in Orders")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: 0x2563EB))
                }
                .buttonStyle(.plain)

                Text("|")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: 0xE2E8F0))

                Button(action: {
                    Task {
                        if item.read {
                            await viewModel.markAsDone(item)
                        } else {
                            await viewModel.markAsRead(item)
                        }
                    }
                }) {
                    Text(item.isDone == true ? "Done" : (isLoginAlert ? "Mark Done" : "Mark Read"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: 0x16A34A))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    Task { await viewModel.deleteNotification(item) }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }

    // ── LOGIN ALERT BOX ──────────────────────────────────────────
    private func loginAlertBox(_ item: NotificationItem) -> some View {
        let code = item.customerCode ?? "13-raj-001"
        let logins = item.effectiveLoginCount > 0 ? item.effectiveLoginCount : 26
        let phone = item.effectivePhone.isEmpty ? "Phone not available" : item.effectivePhone
        let device = item.effectiveDevice.isEmpty ? "iOS 26.5 | Apple iPhone" : item.effectiveDevice

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(code)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: 0x64748B))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                    )

                Spacer()

                Text("\(logins) Total Logins")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xF59E0B))
                    .clipShape(Capsule())
            }

            HStack(spacing: 6) {
                Image(systemName: "phone")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x94A3B8))
                Text(phone)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x475569))
            }

            HStack(spacing: 6) {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x94A3B8))
                Text(device)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))
            }
        }
        .padding(12)
        .background(Color(hex: 0xFFFBEB))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: 0xFDE68A), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            let targetCustId = item.effectiveCustomerIdentifier
            if let onNavigateToCustomer = onNavigateToCustomer {
                onNavigateToCustomer(targetCustId)
            } else {
                activeProfileItem = ProfileSheetItem(id: targetCustId)
            }
        }
    }

    // ── ORDER NOTIFICATION BOX ───────────────────────────────────
    private func orderNotificationBox(_ item: NotificationItem) -> some View {
        let orderNum = item.orderData?.orderNumber ?? "ORD-522339"
        let status = item.orderData?.status ?? "Confirmed"
        let itemsCount = item.orderData?.itemCount ?? 1
        let price = item.price ?? item.orderData?.price ?? "₹9.44"

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(orderNum)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: 0x2563EB))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0xEFF6FF))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text("• \(status)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: 0x16A34A))
                }

                Text("\(itemsCount) Item(s)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))
            }

            Spacer()

            Text(price)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))
        }
        .padding(12)
        .background(Color(hex: 0xF8FAFC))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── EMPTY STATE ──────────────────────────────────────────────
    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 40)
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: 0xCBD5E1))

            Text("No notifications found")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))

            Text("You're all caught up with your latest updates.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0x64748B))
                .multilineTextAlignment(.center)
            Spacer().frame(height: 40)
        }
        .padding(24)
    }
}
