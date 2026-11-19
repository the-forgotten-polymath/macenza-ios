import SwiftUI

// ── Apple Liquid Glass Floating Dock ──────────────────────────────────
// Translucent frosted glass dock (.ultraThinMaterial) with specular rim
// reflections, vibrant electric blue active pill, and live backdrop blur.

public enum ManagementTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case customers = "Customers"
    case orders = "Orders"
    case inventory = "Inventory"
    case ledger = "Ledger"

    public var id: String { rawValue }

    public var icon: String {
        return icon(isSelected: true)
    }

    public func icon(isSelected: Bool) -> String {
        switch self {
        case .dashboard: return isSelected ? "square.grid.2x2.fill" : "square.grid.2x2"
        case .customers: return isSelected ? "person.2.fill" : "person.2"
        case .orders: return isSelected ? "list.clipboard.fill" : "list.clipboard"
        case .inventory: return isSelected ? "shippingbox.fill" : "shippingbox"
        case .ledger: return isSelected ? "book.closed.fill" : "book.closed"
        }
    }

    public var matchingDrawerItem: AppDrawerItem {
        switch self {
        case .dashboard: return .dashboard
        case .customers: return .customers
        case .orders: return .orders
        case .inventory: return .inventory
        case .ledger: return .ledgers
        }
    }

    public var requiredModule: Module? {
        switch self {
        case .dashboard: return nil
        case .customers: return .customers
        case .orders: return .orders
        case .inventory: return .inventory
        case .ledger: return .financials
        }
    }

    public static func from(drawerItem: AppDrawerItem) -> ManagementTab? {
        switch drawerItem {
        case .dashboard: return .dashboard
        case .customers: return .customers
        case .orders: return .orders
        case .inventory: return .inventory
        case .ledgers: return .ledger
        default: return nil
        }
    }
}

public enum CustomerNavTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case category = "Category"
    case orders = "Orders"
    case ledger = "Ledger"
    case profile = "Profile"

    public var id: String { rawValue }

    public var icon: String {
        return icon(isSelected: true)
    }

    public func icon(isSelected: Bool) -> String {
        switch self {
        case .dashboard: return isSelected ? "square.grid.2x2.fill" : "square.grid.2x2"
        case .category: return "shapes"
        case .orders: return isSelected ? "list.clipboard.fill" : "list.clipboard"
        case .ledger: return isSelected ? "book.closed.fill" : "book.closed"
        case .profile: return isSelected ? "person.fill" : "person"
        }
    }
}

// ── Management Floating Liquid Glass Bottom Dock ──────────────────────
public struct ManagementBottomNavBar: View {
    @Binding public var selectedTab: ManagementTab?
    public var onSelect: (ManagementTab) -> Void

    public init(selectedTab: Binding<ManagementTab?>, onSelect: @escaping (ManagementTab) -> Void) {
        self._selectedTab = selectedTab
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(ManagementTab.allCases) { tab in
                let isSelected = selectedTab == tab

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        onSelect(tab)
                    }
                } label: {
                    if isSelected {
                        // Glowing Electric Blue Glass Active Pill (VisionOS style)
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13, weight: .bold))
                            Text(tab.rawValue.uppercased())
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .tracking(0.3)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(LiquidTheme.activePillGradient)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: LiquidTheme.electricBlue.opacity(0.45), radius: 8, x: 0, y: 3)
                        .layoutPriority(1)
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // Inactive Crisp Liquid Glass Icon (Pure white with subtle translucency)
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .frame(width: 42)
                            .padding(.vertical, 9)
                            .contentShape(Rectangle())
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            TintedLiquidGlassCapsule()
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// ── Customer Floating Liquid Glass Bottom Dock ─────────────────────────
public struct CustomerBottomNavBar: View {
    @Binding public var selectedTab: CustomerNavTab
    public var onSelect: (CustomerNavTab) -> Void

    public init(selectedTab: Binding<CustomerNavTab>, onSelect: @escaping (CustomerNavTab) -> Void) {
        self._selectedTab = selectedTab
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(CustomerNavTab.allCases) { tab in
                let isSelected = selectedTab == tab

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        onSelect(tab)
                    }
                } label: {
                    if isSelected {
                        // Glowing Electric Blue Glass Active Pill
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13, weight: .bold))
                            Text(tab.rawValue.uppercased())
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .tracking(0.3)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(LiquidTheme.activePillGradient)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: LiquidTheme.electricBlue.opacity(0.45), radius: 8, x: 0, y: 3)
                        .layoutPriority(1)
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // Inactive Crisp Liquid Glass Icon
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .frame(width: 42)
                            .padding(.vertical, 9)
                            .contentShape(Rectangle())
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            TintedLiquidGlassCapsule()
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
