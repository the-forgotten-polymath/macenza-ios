import Foundation
import SwiftUI

public enum NotificationFilter: String, CaseIterable {
    case all = "All"
    case unread = "Unread"
    case orders = "Orders"
    case security = "Security Logins"
}

@Observable
public final class NotificationViewModel {
    public var notifications: [NotificationItem] = []
    public var selectedFilter: NotificationFilter = .all
    public var searchQuery: String = ""
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    public init() {}

    public var filteredNotifications: [NotificationItem] {
        notifications.filter { item in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .unread: matchesFilter = !item.read
            case .orders: matchesFilter = item.isOrderNotification
            case .security: matchesFilter = item.isSecurityAlert
            }

            let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesSearch = q.isEmpty ||
                item.title.lowercased().contains(q) ||
                item.message.lowercased().contains(q) ||
                (item.productTitle?.lowercased().contains(q) == true) ||
                (item.customerCode?.lowercased().contains(q) == true) ||
                (item.orderData?.orderNumber?.lowercased().contains(q) == true)

            return matchesFilter && matchesSearch
        }
    }

    public var unreadCount: Int {
        notifications.filter { !$0.read }.count
    }

    public var ordersCount: Int {
        notifications.filter { $0.isOrderNotification }.count
    }

    public func loadNotifications() async {
        guard let session = SessionManager.shared.session else { return }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let items = try await NotificationService.shared.fetchNotifications(
                token: session.token,
                role: session.role,
                customerEmail: session.customerEmail,
                customerCode: session.customerCode,
                customerId: session.userId
            )
            await MainActor.run {
                self.notifications = items
                self.isLoading = false
                SessionManager.shared.updateUnreadCount(self.unreadCount)
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    public func markAsRead(_ item: NotificationItem) async {
        guard let session = SessionManager.shared.session else { return }
        do {
            try await NotificationService.shared.markAsRead(token: session.token, id: item.id)
            await MainActor.run {
                if let index = notifications.firstIndex(where: { $0.id == item.id }) {
                    notifications[index].read = true
                    SessionManager.shared.updateUnreadCount(self.unreadCount)
                }
            }
        } catch {
            print("Failed to mark notification read: \(error)")
        }
    }

    public func markAsDone(_ item: NotificationItem) async {
        guard let session = SessionManager.shared.session else { return }
        do {
            try await NotificationService.shared.markAsDone(token: session.token, id: item.id)
            await MainActor.run {
                notifications.removeAll { $0.id == item.id }
                SessionManager.shared.updateUnreadCount(self.unreadCount)
            }
        } catch {
            print("Failed to mark notification done: \(error)")
        }
    }

    public func deleteNotification(_ item: NotificationItem) async {
        guard let session = SessionManager.shared.session else { return }
        do {
            try await NotificationService.shared.deleteNotification(token: session.token, id: item.id)
            await MainActor.run {
                notifications.removeAll { $0.id == item.id }
                SessionManager.shared.updateUnreadCount(self.unreadCount)
            }
        } catch {
            print("Failed to delete notification: \(error)")
        }
    }

    public func markAllAsRead() async {
        guard let session = SessionManager.shared.session else { return }
        do {
            let updated = try await NotificationService.shared.markAllAsRead(
                token: session.token,
                role: session.role,
                customerEmail: session.customerEmail,
                customerCode: session.customerCode,
                customerId: session.userId
            )
            await MainActor.run {
                self.notifications = updated.filter { $0.isDone != true }
                SessionManager.shared.updateUnreadCount(self.unreadCount)
            }
        } catch {
            print("Failed to mark all read: \(error)")
        }
    }

    public func clearAllDone() async {
        guard let session = SessionManager.shared.session else { return }
        do {
            try await NotificationService.shared.markAllAsDone(
                token: session.token,
                role: session.role,
                customerEmail: session.customerEmail,
                customerCode: session.customerCode,
                customerId: session.userId
            )
            await loadNotifications()
        } catch {
            print("Failed to clear done: \(error)")
        }
    }
}
