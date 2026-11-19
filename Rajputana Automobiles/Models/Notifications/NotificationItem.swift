import Foundation

public struct NotificationItem: Codable, Identifiable {
    public var id: String { _id ?? itemId ?? UUID().uuidString }

    public let _id: String?
    public let itemId: String?
    public let type: String
    public let title: String
    public let message: String
    public let timestamp: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let date: String?
    public let isToday: Bool?
    public var read: Bool
    public var isDone: Bool?
    public let severity: String?
    public let link: String?
    public let targetRole: String?
    public let customerCode: String?
    public let customerEmail: String?
    public let customerId: String?
    public let price: String?
    public let productTitle: String?
    public let orderData: NotificationOrderData?

    enum CodingKeys: String, CodingKey {
        case _id
        case itemId = "id"
        case type, title, message, timestamp, createdAt, updatedAt, date, isToday
        case read, isDone, severity, link, targetRole, customerCode, customerEmail, customerId
        case price, productTitle, orderData
    }

    public var effectiveTimestamp: String {
        return timestamp ?? createdAt ?? date ?? ""
    }

    public var isOrderNotification: Bool {
        return type.lowercased().contains("order")
    }

    public var isSecurityAlert: Bool {
        return type.lowercased() == "customer_login_alert" || type.lowercased().contains("security")
    }

    public var effectiveLoginCount: Int {
        orderData?.loginCount ?? 0
    }

    public var effectiveCustomerIdentifier: String {
        if let id = customerId, !id.isEmpty { return id }
        if let id = orderData?.customerId, !id.isEmpty { return id }
        if let code = customerCode, !code.isEmpty { return code }
        if let code = orderData?.customerCode, !code.isEmpty { return code }
        if let link = link {
            let parts = link.split(separator: "/")
            if let last = parts.last, !last.isEmpty, link.contains("customer") {
                return String(last)
            }
        }
        return "13-raj-001"
    }

    public var effectivePhone: String {
        orderData?.customerPhone ?? orderData?.phone ?? ""
    }

    public var effectiveLocation: String {
        orderData?.customerLocation ?? orderData?.location ?? ""
    }

    public var effectiveDevice: String {
        orderData?.deviceInfo ?? ""
    }
}

public struct NotificationOrderData: Codable {
    public let orderId: String?
    public let orderNumber: String?
    public let itemCount: Int?
    public let status: String?
    public let customerName: String?
    public let total: Double?
    public let price: String?
    public let loginCount: Int?
    public let deviceInfo: String?
    public let customerLocation: String?
    public let location: String?
    public let customerPhone: String?
    public let phone: String?
    public let customerCode: String?
    public let customerId: String?
}

public struct NotificationActionResponse: Codable {
    public let success: Bool?
    public let id: String?
    public let read: Bool?
    public let isDone: Bool?
}

public struct MarkAllNotificationRequest: Codable {
    public let role: String
    public let customerEmail: String?
    public let customerCode: String?
    public let customerId: String?

    public init(role: String, customerEmail: String? = nil, customerCode: String? = nil, customerId: String? = nil) {
        self.role = role
        self.customerEmail = customerEmail
        self.customerCode = customerCode
        self.customerId = customerId
    }
}
