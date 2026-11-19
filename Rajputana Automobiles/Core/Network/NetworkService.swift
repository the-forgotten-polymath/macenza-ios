import Foundation

public final class NetworkService {
    public static let shared = NetworkService()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60.0
        configuration.timeoutIntervalForResource = 120.0
        self.session = URLSession(configuration: configuration)
    }

    public func request<T: Decodable>(_ endpoint: APIEndpoint, token: String? = nil) async throws -> T {
        let urlRequest = try endpoint.makeURLRequest(token: token)

        #if DEBUG
        print("🌐 [REQ] \(urlRequest.httpMethod ?? "") \(urlRequest.url?.absoluteString ?? "")")
        #endif

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        #if DEBUG
        print("📥 [RESP \(httpResponse.statusCode)] \(urlRequest.url?.path ?? "") (\(data.count) bytes)")
        #endif

        // HTTP status handling matching Android error logic
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("❌ [DECODE ERROR] \(error) on data:\n\(String(data: data, encoding: .utf8) ?? "")")
                #endif
                throw APIError.decodingError(error)
            }

        case 401:
            throw APIError.unauthorized

        case 403:
            throw APIError.forbidden

        case 404:
            if let serverError = try? JSONDecoder().decode(ServerErrorPayload.self, from: data),
               let msg = serverError.message, !msg.isEmpty {
                throw APIError.serverError(statusCode: 404, message: msg)
            }
            throw APIError.notFound

        case 413:
            throw APIError.fileTooLarge

        case 503:
            let serverError = try? JSONDecoder().decode(ServerErrorPayload.self, from: data)
            throw APIError.maintenanceMode(serverError?.message ?? "Service temporarily under maintenance.")

        default:
            let serverError = try? JSONDecoder().decode(ServerErrorPayload.self, from: data)
            let message = serverError?.message ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    /// Overload for calls that return raw data (e.g. downloads)
    public func requestRaw(_ endpoint: APIEndpoint, token: String? = nil) async throws -> Data {
        let urlRequest = try endpoint.makeURLRequest(token: token)
        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500, message: "Download failed")
        }
        return data
    }
}
