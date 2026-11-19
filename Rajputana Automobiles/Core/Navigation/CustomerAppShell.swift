import SwiftUI

public struct CustomerAppShell: View {
    private static var initialTab: CustomerNavTab {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-openCategoryTab") { return .category }
        if args.contains("-openOrdersTab") { return .orders }
        if args.contains("-openLedgerTab") { return .ledger }
        if args.contains("-openProfileTab") { return .profile }
        return .dashboard
    }

    @State private var selectedTab: CustomerNavTab = initialTab
    @State private var showCartSheet: Bool = ProcessInfo.processInfo.arguments.contains("-openCartSheet")
    @State private var showNotificationsSheet: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Top App Bar matching Android CustomerToolbar.kt 1:1
            customerTopBar

            // Main Tab Content
            Group {
                switch selectedTab {
                case .dashboard:
                    NavigationStack {
                        CustomerCatalogView(
                            onViewAllCategories: {
                                selectedTab = .category
                            },
                            onOpenCart: {
                                showCartSheet = true
                            }
                        )
                        .toolbar(.hidden, for: .navigationBar)
                    }
                case .category:
                    NavigationStack {
                        CategoryAccordionView()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                case .orders:
                    NavigationStack {
                        CustomerOrderListView()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                case .ledger:
                    NavigationStack {
                        CustomerLedgerRouteView()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                case .profile:
                    NavigationStack {
                        UserProfileView()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom Navigation Bar matching Android BottomNavigationBar.kt 1:1
            customerBottomBar
        }
        .background(Color(hex: 0xF8FAFC))
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showCartSheet) {
            CartFlowView()
        }
        .sheet(isPresented: $showNotificationsSheet) {
            NotificationListView()
        }
        .task {
            await SessionManager.shared.refreshUnreadNotificationCount()
            await CartViewModel.shared.loadCart()
            if ProcessInfo.processInfo.arguments.contains("-openNotificationsSheet") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showNotificationsSheet = true
                }
            }
        }
    }

    // ── Customer Top Bar matching Android CustomerToolbar.kt 1:1 ──
    private var customerTopBar: some View {
        HStack(spacing: 12) {
            Image("app_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("Rajputana Automobiles")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))
                .lineLimit(1)

            Spacer()

            Button {
                showNotificationsSheet = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(Color(hex: 0x0F172A))
                        .frame(width: 36, height: 36)

                    let unread = SessionManager.shared.unreadNotificationCount
                    if unread > 0 {
                        Circle()
                            .fill(Color(hex: 0xDC2626))
                            .frame(width: 8, height: 8)
                            .offset(x: -4, y: 6)
                    }
                }
            }
            .buttonStyle(.plain)

            Button {
                showCartSheet = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cart")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(Color(hex: 0x0F172A))
                        .frame(width: 36, height: 36)

                    let count = CartViewModel.shared.totalUnits
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 17, height: 17)
                            .background(Color(hex: 0x2563EB))
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white.ignoresSafeArea(edges: .top))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(hex: 0xE2E8F0)),
            alignment: .bottom
        )
    }

    // ── Customer Bottom Bar matching Android BottomNavigationBar.kt 1:1 ──
    private var customerBottomBar: some View {
        HStack(spacing: 0) {
            ForEach(CustomerNavTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? Color(hex: 0xDDE9FF) : Color.clear)
                                .frame(width: 44, height: 28)

                            if tab == .category {
                                CategoryShapesIcon(
                                    isSelected: isSelected,
                                    color: isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x64748B)
                                )
                            } else {
                                Image(systemName: tab.icon(isSelected: isSelected))
                                    .font(.system(size: 17, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x64748B))
                            }
                        }

                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x64748B))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(hex: 0xE2E8F0)),
            alignment: .top
        )
    }
}

// ── Category Shapes Icon matching Google Material Icons.Outlined.Category 1:1
private struct CategoryShapesIcon: View {
    let isSelected: Bool
    let color: Color

    var body: some View {
        ZStack {
            // Triangle top
            Image(systemName: isSelected ? "triangle.fill" : "triangle")
                .font(.system(size: 8, weight: isSelected ? .bold : .medium))
                .foregroundColor(color)
                .offset(y: -5)

            // Square bottom left
            Image(systemName: isSelected ? "square.fill" : "square")
                .font(.system(size: 7, weight: isSelected ? .bold : .medium))
                .foregroundColor(color)
                .offset(x: -5.5, y: 5)

            // Circle bottom right
            Image(systemName: isSelected ? "circle.fill" : "circle")
                .font(.system(size: 7, weight: isSelected ? .bold : .medium))
                .foregroundColor(color)
                .offset(x: 5.5, y: 5)
        }
        .frame(width: 22, height: 22)
    }
}
