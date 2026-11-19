import Foundation

public enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case forbidden
    case notFound
    case maintenanceMode(String)
    case fileTooLarge
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case .unauthorized:
            return "Session expired or unauthorized. Please sign in again."
        case .forbidden:
            return "You do not have permission to perform this action."
        case .notFound:
            return "The requested resource was not found."
        case .maintenanceMode(let message):
            return message.isEmpty ? "The service is currently under maintenance." : message
        case .fileTooLarge:
            return "The selected document exceeds the 10 MB limit."
        case .serverError(let code, let msg):
            return msg.isEmpty ? "Server returned error (HTTP \(code))." : msg
        case .decodingError(let error):
            return "Failed to parse server response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network connection issue: \(error.localizedDescription)"
        case .unknown:
            return "An unexpected error occurred."
        }
    }
}

public struct ServerErrorPayload: Codable {
    public let message: String?
    public let code: String?
    public let success: Bool?
}
