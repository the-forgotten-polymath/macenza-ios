import Foundation
import SwiftUI

@Observable
public final class SessionManager {
    public static let shared = SessionManager()

    public var session: AuthSession? = nil
    public var isAuthenticated: Bool { session != nil }

    // Badges shared across app shell
    public var unreadNotificationCount: Int = 0
    public var cartItemCount: Int = 0
    public var cachedCustomerDetail: CustomerDetailModel? = nil

    private var heartbeatTask: Task<Void, Never>? = nil
    private var lastPermissionRefreshTime: Date? = nil

    private let sessionKeychainKey = "rajputana_auth_session"

    private init() {
        restoreSession()
    }

    public func signIn(_ newSession: AuthSession) {
        self.session = newSession
        saveSession(newSession)
        startHeartbeat()
    }

    public func signOut() {
        heartbeatTask?.cancel()
        heartbeatTask = nil

        if let token = session?.token {
            Task {
                await AuthService.shared.logout(token: token)
            }
        }

        self.session = nil
        self.unreadNotificationCount = 0
        self.cartItemCount = 0
        self.cachedCustomerDetail = nil
        KeychainStore.delete(key: sessionKeychainKey)
    }

    public func updatePermissions(_ permissions: [String: ModulePermission]) {
        self.session?.permissions = permissions
        if let s = self.session {
            self.saveSession(s)
        }
    }

    public func saveSession(_ session: AuthSession) {
        if let encoded = try? JSONEncoder().encode(session) {
            _ = KeychainStore.save(key: sessionKeychainKey, data: encoded)
        }
    }

    private func restoreSession() {
        if ProcessInfo.processInfo.arguments.contains("-resetSession") || ProcessInfo.processInfo.arguments.contains("-autoLoginCustomer") || ProcessInfo.processInfo.arguments.contains("-autoLoginAdmin") || ProcessInfo.processInfo.arguments.contains("-autoLoginAdminStaff") {
            KeychainStore.delete(key: sessionKeychainKey)
            self.session = nil
            return
        }

        if let data = KeychainStore.loadData(key: sessionKeychainKey),
           let decoded = try? JSONDecoder().decode(AuthSession.self, from: data) {
            self.session = decoded
            startHeartbeat()
        }
    }

    // ── 30-Second Heartbeat Task ───────────────────────────
    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                guard let self = self, let token = self.session?.token else { break }

                let valid = await AuthService.shared.checkHeartbeat(token: token)
                if !valid {
                    await MainActor.run {
                        self.signOut()
                    }
                    break
                }
            }
        }
    }

    // ── Foreground Permission Refresh (Max once every 5 minutes) ─
    public func refreshPermissionsIfStale() async {
        guard let current = session else { return }

        if let last = lastPermissionRefreshTime, Date().timeIntervalSince(last) < 300 {
            return // Skip if checked in last 5 minutes
        }

        if let fresh = await AuthService.shared.refreshPermissions(token: current.token, roleName: current.backendRole) {
            await MainActor.run {
                self.session?.permissions = fresh
                if let updated = self.session {
                    self.saveSession(updated)
                }
                self.lastPermissionRefreshTime = Date()
            }
        }
    }

    public func updateCartCount(_ count: Int) {
        self.cartItemCount = count
    }

    public func refreshUnreadNotificationCount() async {
        guard let session = session else { return }
        do {
            let list = try await NotificationService.shared.fetchNotifications(
                token: session.token,
                role: session.role,
                customerEmail: session.customerEmail,
                customerCode: session.customerCode,
                customerId: session.userId
            )
            let unread = list.filter { $0.read != true }.count
            await MainActor.run {
                self.unreadNotificationCount = unread
            }
        } catch {
            // Ignore polling errors
        }
    }

    public func updateUnreadCount(_ count: Int) {
        self.unreadNotificationCount = count
    }
}
