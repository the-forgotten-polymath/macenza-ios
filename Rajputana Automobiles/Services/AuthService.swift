import Foundation
import UIKit

public final class AuthService {
    public static let shared = AuthService()
    private let network = NetworkService.shared

    private init() {}

    public func getDeviceInfo() -> String {
        let osVersion = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        return "iOS \(osVersion) | Apple \(model)"
    }

    public func login(email: String, password: String) async throws -> AuthSession {
        let requestBody = LoginRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            deviceInfo: getDeviceInfo()
        )
        let bodyData = try JSONEncoder().encode(requestBody)

        let loginEndpoint = APIEndpoint(
            path: "api/auth/login",
            method: .post,
            body: bodyData
        )

        let loginResponse: LoginResponse = try await network.request(loginEndpoint)
        let token = loginResponse.token

        // Fetch role permissions
        let rolesEndpoint = APIEndpoint(path: "api/roles", method: .get)
        let roles: [RoleResponse] = (try? await network.request(rolesEndpoint, token: token)) ?? []

        let backendRole = loginResponse.role ?? loginResponse.user?.role ?? "admin"
        let workspaceRole = WorkspaceRole.fromBackend(backendRole)

        // Find permissions matching role
        var permissions: [String: ModulePermission] = [:]
        if let matchedRole = roles.first(where: { $0.name.caseInsensitiveCompare(backendRole) == .orderedSame }) {
            permissions = matchedRole.permissions
        }

        // Extract JWT partyName if present in token
        var jwtPartyName: String? = nil
        let jwtParts = token.components(separatedBy: ".")
        if jwtParts.count >= 2 {
            var base64 = jwtParts[1]
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            while base64.count % 4 != 0 {
                base64.append("=")
            }
            if let data = Data(base64Encoded: base64),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                jwtPartyName = json["partyName"] as? String
            }
        }

        let user = loginResponse.user
        let ledgerName = jwtPartyName
            ?? user?.tallyLedgerName
            ?? user?.customer?.tallyLedgerName
            ?? (user?.name?.isEmpty == false ? user?.name : nil)

        if let cust = user?.customer {
            Task { @MainActor in
                SessionManager.shared.cachedCustomerDetail = cust
            }
        }

        let session = AuthSession(
            token: token,
            userId: user?.id ?? user?._id ?? UUID().uuidString,
            name: user?.name?.isEmpty == false ? user!.name! : (jwtPartyName ?? "User"),
            email: user?.email ?? email,
            role: workspaceRole,
            backendRole: backendRole,
            companyName: user?.companyName ?? "Rajputana Automobiles",
            permissions: permissions,
            customerCode: user?.code,
            customerEmail: user?.customerEmail ?? user?.email,
            customerPhone: user?.phone,
            customerAddress: user?.address ?? user?.officeAddress,
            gstin: user?.gstin,
            tallyLedgerName: ledgerName
        )

        return session
    }

    public func checkHeartbeat(token: String) async -> Bool {
        let endpoint = APIEndpoint(path: "api/auth/heartbeat", method: .get)
        do {
            let response: HeartbeatResponse = try await network.request(endpoint, token: token)
            return response.valid ?? true
        } catch {
            return false
        }
    }

    public func refreshPermissions(token: String, roleName: String) async -> [String: ModulePermission]? {
        let endpoint = APIEndpoint(path: "api/roles", method: .get)
        do {
            let roles: [RoleResponse] = try await network.request(endpoint, token: token)
            if let matched = roles.first(where: { $0.name.caseInsensitiveCompare(roleName) == .orderedSame }) {
                return matched.permissions
            }
        } catch {
            print("Failed to refresh permissions: \(error)")
        }
        return nil
    }

    public func logout(token: String) async {
        let endpoint = APIEndpoint(path: "api/auth/logout", method: .post)
        let _: LogoutResponse? = try? await network.request(endpoint, token: token)
    }

    public func changePassword(token: String, identifier: String, oldPass: String, newPass: String) async throws -> Bool {
        let body: [String: String] = [
            "identifier": identifier,
            "oldPassword": oldPass,
            "newPassword": newPass
        ]
        let data = try JSONSerialization.data(withJSONObject: body)
        let endpoint = APIEndpoint(path: "api/auth/change-password", method: .post, body: data)
        let response: [String: AnyCodable] = try await network.request(endpoint, token: token)
        return (response["success"]?.value as? Bool) ?? true
    }

    // Demo Credentials Helper matching Android AuthRepository
    public static func demoCredentials(for role: WorkspaceRole) -> (email: String, pass: String) {
        switch role {
        case .superadmin:
            return ("superadmin@automob.in", "superadmin123")
        case .admin:
            return ("admin@automob.in", "admin123")
        case .customer:
            return ("13-raj-001", "123456789")
        }
    }
}

public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) { value = b }
        else if let i = try? container.decode(Int.self) { value = i }
        else if let d = try? container.decode(Double.self) { value = d }
        else if let s = try? container.decode(String.self) { value = s }
        else { value = "" }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let b = value as? Bool { try container.encode(b) }
        else if let i = value as? Int { try container.encode(i) }
        else if let d = value as? Double { try container.encode(d) }
        else if let s = value as? String { try container.encode(s) }
    }
}
