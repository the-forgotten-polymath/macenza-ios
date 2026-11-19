import Foundation

public final class SettingsService {
    public static let shared = SettingsService()
    private let network = NetworkService.shared

    private init() {}

    public func fetchCompanyProfile(token: String) async throws -> CompanyProfile {
        let endpoint = APIEndpoint(path: "api/company", method: .get)
        return try await network.request(endpoint, token: token)
    }

    public func updateCompanyProfile(token: String, profile: CompanyProfile) async throws -> CompanyProfile {
        let data = try JSONEncoder().encode(profile)
        let endpoint = APIEndpoint(path: "api/company", method: .put, body: data)
        return try await network.request(endpoint, token: token)
    }

    public func fetchRoles(token: String) async throws -> [RoleResponse] {
        let endpoint = APIEndpoint(path: "api/roles", method: .get)
        return try await network.request(endpoint, token: token)
    }

    public func bulkSavePermissionMatrix(token: String, request: BulkSaveMatrixRequest) async throws {
        let data = try JSONEncoder().encode(request)
        let endpoint = APIEndpoint(path: "api/roles/matrix/bulk-save", method: .put, body: data)
        let _: [String: AnyCodable] = try await network.request(endpoint, token: token)
    }
}
