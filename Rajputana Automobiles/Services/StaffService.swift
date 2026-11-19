import Foundation

public final class StaffService {
    public static let shared = StaffService()
    private let network = NetworkService.shared

    private init() {}

    public func fetchStaff(token: String) async throws -> [StaffModel] {
        let endpoint = APIEndpoint(path: "api/staff", method: .get)
        return try await network.request(endpoint, token: token)
    }

    public func createStaff(token: String, request: StaffRequest) async throws -> StaffModel {
        let data = try JSONEncoder().encode(request)
        let endpoint = APIEndpoint(path: "api/staff", method: .post, body: data)
        return try await network.request(endpoint, token: token)
    }

    public func updateStaff(token: String, id: String, request: StaffRequest) async throws -> StaffModel {
        let data = try JSONEncoder().encode(request)
        let endpoint = APIEndpoint(path: "api/staff/\(id)", method: .put, body: data)
        return try await network.request(endpoint, token: token)
    }

    public func deleteStaff(token: String, id: String) async throws {
        let endpoint = APIEndpoint(path: "api/staff/\(id)", method: .delete)
        let _: [String: AnyCodable] = try await network.request(endpoint, token: token)
    }

    public func uploadAvatar(token: String, email: String, role: String, imageBase64DataUri: String, identifier: String? = nil) async throws -> String {
        var body: [String: String] = [
            "avatarUrl": imageBase64DataUri,
            "role": role,
            "email": email
        ]
        if let id = identifier, !id.isEmpty {
            body["identifier"] = id
        }
        let data = try JSONSerialization.data(withJSONObject: body)
        let endpoint = APIEndpoint(path: "api/auth/upload-avatar", method: .post, body: data)
        let response: [String: AnyCodable] = try await network.request(endpoint, token: token)
        return (response["avatarUrl"]?.value as? String) ?? (response["url"]?.value as? String) ?? ""
    }
}
