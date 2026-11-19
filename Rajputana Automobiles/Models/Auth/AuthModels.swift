import Foundation

public struct LoginRequest: Codable {
    public let email: String
    public let password: String
    public let deviceInfo: String

    public init(email: String, password: String, deviceInfo: String) {
        self.email = email
        self.password = password
        self.deviceInfo = deviceInfo
    }
}

public struct LoginResponse: Codable {
    public let message: String?
    public let token: String
    public let role: String?
    public let user: AuthUserPayload?
}

public struct AuthUserPayload: Codable {
    public let id: String?
    public let _id: String?
    public let code: String?
    public let adminCode: String?
    public let name: String?
    public let email: String?
    public let phone: String?
    public let address: String?
    public let officeAddress: String?
    public let gstin: String?
    public let role: String?
    public let companyName: String?
    public let customerEmail: String?
    public let tallyLedgerName: String?
    public let customer: CustomerDetailModel?
}

public struct HeartbeatResponse: Codable {
    public let valid: Bool?
    public let code: String?
    public let message: String?
}

public struct LogoutResponse: Codable {
    public let success: Bool?
    public let message: String?
}

public struct AuthSession: Codable, Equatable {
    public let token: String
    public let userId: String
    public let name: String
    public let email: String
    public let role: WorkspaceRole
    public let backendRole: String
    public let companyName: String
    public var permissions: [String: ModulePermission]

    // Customer specific identifiers
    public let customerCode: String?
    public let customerEmail: String?
    public let customerPhone: String?
    public let customerAddress: String?
    public let gstin: String?
    public let tallyLedgerName: String?

    public init(
        token: String,
        userId: String,
        name: String,
        email: String,
        role: WorkspaceRole,
        backendRole: String,
        companyName: String,
        permissions: [String: ModulePermission],
        customerCode: String? = nil,
        customerEmail: String? = nil,
        customerPhone: String? = nil,
        customerAddress: String? = nil,
        gstin: String? = nil,
        tallyLedgerName: String? = nil
    ) {
        self.token = token
        self.userId = userId
        self.name = name
        self.email = email
        self.role = role
        self.backendRole = backendRole
        self.companyName = companyName
        self.permissions = permissions
        self.customerCode = customerCode
        self.customerEmail = customerEmail
        self.customerPhone = customerPhone
        self.customerAddress = customerAddress
        self.gstin = gstin
        self.tallyLedgerName = tallyLedgerName
    }

    public var isCustomer: Bool {
        return role == .customer
    }

    public var isStaff: Bool {
        return role == .superadmin || role == .admin
    }

    public var effectiveCustomerIdentifier: String {
        if let code = customerCode, !code.trimmingCharacters(in: .whitespaces).isEmpty {
            return code
        }
        if let cEmail = customerEmail, !cEmail.trimmingCharacters(in: .whitespaces).isEmpty {
            return cEmail
        }
        if !email.trimmingCharacters(in: .whitespaces).isEmpty {
            return email
        }
        return userId
    }

    public func canView(_ module: Module) -> Bool {
        if role == .superadmin { return true }
        if role == .customer {
            // Customer role forces Staff, Audit Logs, Settings off
            if module == .staff || module == .auditLogs || module == .audit || module == .settings {
                return false
            }
            return true
        }
        if let direct = permissions[module.rawValue]?.view {
            return direct
        }
        if let entry = permissions.first(where: { $0.key.caseInsensitiveCompare(module.rawValue) == .orderedSame }) {
            return entry.value.view
        }
        if module == .financials {
            if let leg = permissions["Ledger"]?.view ?? permissions["ledger"]?.view {
                return leg
            }
        }
        return false
    }

    public func canEdit(_ module: Module) -> Bool {
        if role == .superadmin { return true }
        if role == .customer { return false }
        if let direct = permissions[module.rawValue]?.edit {
            return direct
        }
        if let entry = permissions.first(where: { $0.key.caseInsensitiveCompare(module.rawValue) == .orderedSame }) {
            return entry.value.edit
        }
        if module == .financials {
            if let leg = permissions["Ledger"]?.edit ?? permissions["ledger"]?.edit {
                return leg
            }
        }
        return false
    }
}
