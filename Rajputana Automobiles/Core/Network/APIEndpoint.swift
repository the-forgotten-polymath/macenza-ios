import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct APIEndpoint {
    public static let baseURL = "https://api.rajputanaautomobiles.com/"

    public let path: String
    public let method: HTTPMethod
    public var queryItems: [URLQueryItem] = []
    public var headers: [String: String] = [:]
    public var body: Data? = nil
    public var timeoutInterval: TimeInterval = 60.0

    public init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        timeoutInterval: TimeInterval = 60.0
    ) {
        self.path = path.hasPrefix("/") ? String(path.dropFirst()) : path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.timeoutInterval = timeoutInterval
    }

    public func makeURLRequest(token: String?) throws -> URLRequest {
        var urlString = APIEndpoint.baseURL + path
        if URLComponents(string: urlString) == nil {
            if let safe = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed.union(.urlPathAllowed)) {
                urlString = safe
            }
        }
        guard var components = URLComponents(string: urlString) else {
            throw APIError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = method.rawValue

        // Common headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // Bearer token
        if let token = token, !token.isEmpty, !path.contains("api/auth/login") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Custom extra headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = body
        return request
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
