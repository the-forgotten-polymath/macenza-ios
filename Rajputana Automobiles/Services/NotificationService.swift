import Foundation

public final class NotificationService {
    public static let shared = NotificationService()
    private let network = NetworkService.shared

    private init() {}

    public func fetchNotifications(
        token: String,
        role: WorkspaceRole,
        customerEmail: String? = nil,
        customerCode: String? = nil,
        customerId: String? = nil
    ) async throws -> [NotificationItem] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "role", value: role.rawValue)
        ]
        if let email = customerEmail, !email.isEmpty {
            queryItems.append(URLQueryItem(name: "customerEmail", value: email))
        }
        if let code = customerCode, !code.isEmpty {
            queryItems.append(URLQueryItem(name: "customerCode", value: code))
        }
        if let id = customerId, !id.isEmpty {
            queryItems.append(URLQueryItem(name: "customerId", value: id))
        }

        let endpoint = APIEndpoint(path: "api/notifications", method: .get, queryItems: queryItems)
        let items: [NotificationItem] = try await network.request(endpoint, token: token)
        return items.filter { $0.isDone != true }
    }

    public func markAsRead(token: String, id: String) async throws {
        let endpoint = APIEndpoint(path: "api/notifications/\(id)/read", method: .put)
        let _: NotificationActionResponse = try await network.request(endpoint, token: token)
    }

    public func markAsDone(token: String, id: String) async throws {
        let endpoint = APIEndpoint(path: "api/notifications/\(id)/done", method: .put)
        let _: NotificationActionResponse = try await network.request(endpoint, token: token)
    }

    public func deleteNotification(token: String, id: String) async throws {
        let endpoint = APIEndpoint(path: "api/notifications/\(id)", method: .delete)
        let _: NotificationActionResponse = try await network.request(endpoint, token: token)
    }

    public func markAllAsRead(
        token: String,
        role: WorkspaceRole,
        customerEmail: String? = nil,
        customerCode: String? = nil,
        customerId: String? = nil
    ) async throws -> [NotificationItem] {
        let body = MarkAllNotificationRequest(role: role.rawValue, customerEmail: customerEmail, customerCode: customerCode, customerId: customerId)
        let data = try JSONEncoder().encode(body)
        let endpoint = APIEndpoint(path: "api/notifications/read-all", method: .put, body: data)
        return try await network.request(endpoint, token: token)
    }

    public func markAllAsDone(
        token: String,
        role: WorkspaceRole,
        customerEmail: String? = nil,
        customerCode: String? = nil,
        customerId: String? = nil
    ) async throws {
        let body = MarkAllNotificationRequest(role: role.rawValue, customerEmail: customerEmail, customerCode: customerCode, customerId: customerId)
        let data = try JSONEncoder().encode(body)
        let endpoint = APIEndpoint(path: "api/notifications/done-all", method: .put, body: data)
        let _: NotificationActionResponse = try await network.request(endpoint, token: token)
    }
}
