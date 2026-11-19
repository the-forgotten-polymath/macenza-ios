import Foundation

public struct TallySyncResponse: Codable {
    public let success: Bool
    public let itemsUpdated: Int?
    public let syncedAt: String?
    public let message: String?
}

public final class InventoryService {
    public static let shared = InventoryService()
    private let network = NetworkService.shared

    private init() {}

    public func fetchInventory(token: String, forceRefresh: Bool = false) async throws -> [InventoryItem] {
        var queryItems: [URLQueryItem] = []
        if forceRefresh {
            queryItems.append(URLQueryItem(name: "nocache", value: "\(Int(Date().timeIntervalSince1970))"))
        }

        let endpoint = APIEndpoint(path: "api/inventory", method: .get, queryItems: queryItems)
        return try await network.request(endpoint, token: token)
    }

    public func fetchInventoryItem(token: String, id: String) async throws -> InventoryItem {
        let endpoint = APIEndpoint(path: "api/inventory/\(id)", method: .get)
        return try await network.request(endpoint, token: token)
    }

    public func updateInventoryItem(token: String, id: String, changes: [String: Any]) async throws -> InventoryItem {
        let data = try JSONSerialization.data(withJSONObject: changes)
        let endpoint = APIEndpoint(path: "api/inventory/\(id)", method: .put, body: data)
        return try await network.request(endpoint, token: token)
    }

    public func syncTally(token: String) async throws -> TallySyncResponse {
        let endpoint = APIEndpoint(path: "api/inventory/tally-sync", method: .post)
        return try await network.request(endpoint, token: token)
    }

    public func deleteItem(token: String, id: String) async throws {
        let endpoint = APIEndpoint(path: "api/inventory/\(id)", method: .delete)
        let _: [String: AnyCodable] = try await network.request(endpoint, token: token)
    }

    public func uploadItemImage(token: String, id: String, imageBase64DataUri: String) async throws -> InventoryItem {
        let body = ["image": imageBase64DataUri]
        let data = try JSONSerialization.data(withJSONObject: body)
        let endpoint = APIEndpoint(path: "api/inventory/\(id)/upload-image", method: .post, body: data)
        return try await network.request(endpoint, token: token)
    }
}
