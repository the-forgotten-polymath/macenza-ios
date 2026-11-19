import SwiftUI

public enum AppDrawerItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case customers = "Customers"
    case orders = "Orders"
    case inventory = "Inventory"
    case ledgers = "Ledger"
    case staff = "Staff"
    case audit = "Audit Logs"
    case settings = "Settings"
    case profile = "Profile"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .dashboard: return "gauge.with.needle.fill"
        case .customers: return "person.2.fill"
        case .orders: return "cart.fill"
        case .inventory: return "shippingbox.fill"
        case .ledgers: return "book.closed.fill"
        case .staff: return "person.3.fill"
        case .audit: return "clock.arrow.circlepath"
        case .settings: return "gearshape.2.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }

    public var requiredModule: Module? {
        switch self {
        case .dashboard: return nil
        case .customers: return .customers
        case .orders: return .orders
        case .inventory: return .inventory
        case .ledgers: return .financials
        case .staff: return .staff
        case .audit: return .auditLogs
        case .settings: return .settings
        case .profile: return nil
        }
    }
}
