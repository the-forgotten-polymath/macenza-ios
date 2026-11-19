import Foundation

public final class ActivityService {
    public static let shared = ActivityService()
    private let network = NetworkService.shared

    private init() {}

    public func fetchActivities(token: String) async throws -> [ActivityLog] {
        let endpoint = APIEndpoint(path: "api/activities", method: .get)
        return try await network.request(endpoint, token: token)
    }
}
