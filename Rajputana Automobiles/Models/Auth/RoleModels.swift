import Foundation

public enum WorkspaceRole: String, Codable {
    case superadmin = "superadmin"
    case admin = "admin"
    case customer = "customer"

    public static func fromBackend(_ value: String?) -> WorkspaceRole {
        guard let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return .admin
        }
        switch normalized {
        case "superadmin", "super_admin", "root":
            return .superadmin
        case "customer", "dealer", "buyer":
            return .customer
        default:
            return .admin
        }
    }

    public var displayName: String {
        switch self {
        case .superadmin: return "Super Admin"
        case .admin: return "Admin / Staff"
        case .customer: return "Customer / Dealer"
        }
    }
}

public enum Module: String, CaseIterable, Codable {
    case orders = "Orders"
    case customers = "Customers"
    case dealers = "Dealers"
    case inventory = "Inventory"
    case financials = "Financials"
    case staff = "Staff"
    case auditLogs = "Audit Logs"
    case audit = "Audit"
    case settings = "Settings"
}

public struct ModulePermission: Codable, Equatable {
    public var view: Bool
    public var edit: Bool

    public init(view: Bool = false, edit: Bool = false) {
        self.view = view
        self.edit = edit
    }
}

public struct RoleResponse: Codable, Identifiable {
    public var id: String { _id ?? roleId }
    public let _id: String?
    public let roleId: String
    public let name: String
    public let description: String?
    public let badgeColor: String?
    public let isMaster: Bool?
    public let isCustom: Bool?
    public let createdBy: String?
    public var permissions: [String: ModulePermission]

    enum CodingKeys: String, CodingKey {
        case _id
        case roleId = "id"
        case name
        case description
        case badgeColor
        case isMaster
        case isCustom
        case createdBy
        case permissions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try? container.decode(String.self, forKey: ._id)
        self.roleId = (try? container.decode(String.self, forKey: .roleId)) ?? ""
        self.name = (try? container.decode(String.self, forKey: .name)) ?? ""
        self.description = try? container.decode(String.self, forKey: .description)
        self.badgeColor = try? container.decode(String.self, forKey: .badgeColor)
        self.isMaster = try? container.decode(Bool.self, forKey: .isMaster)
        self.isCustom = try? container.decode(Bool.self, forKey: .isCustom)
        self.createdBy = try? container.decode(String.self, forKey: .createdBy)
        self.permissions = (try? container.decode([String: ModulePermission].self, forKey: .permissions)) ?? [:]
    }
}
