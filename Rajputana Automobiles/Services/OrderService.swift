import Foundation

public final class OrderService {
    public static let shared = OrderService()
    private let network = NetworkService.shared

    private init() {}

    public func fetchOrders(token: String, customerCode: String? = nil, customerEmail: String? = nil) async throws -> [OrderModel] {
        var queryItems: [URLQueryItem] = []
        if let code = customerCode, !code.isEmpty {
            queryItems.append(URLQueryItem(name: "customerCode", value: code))
        }
        if let email = customerEmail, !email.isEmpty {
            queryItems.append(URLQueryItem(name: "customerEmail", value: email))
        }

        let endpoint = APIEndpoint(path: "api/orders", method: .get, queryItems: queryItems)
        return try await network.request(endpoint, token: token)
    }

    public func fetchOrderById(token: String, id: String) async throws -> OrderModel {
        do {
            let endpoint = APIEndpoint(path: "api/orders/\(id)", method: .get)
            return try await network.request(endpoint, token: token)
        } catch {
            // Fallback: If single order lookup fails (e.g. 404 because id is mongoId, orderNumber, or wrapped), search in list
            let all = try await fetchOrders(token: token)
            if let found = all.first(where: {
                $0.id == id ||
                $0.orderId == id ||
                $0.orderNumber == id ||
                $0._id == id
            }) {
                return found
            }
            throw error
        }
    }

    public func updateOrderStatus(token: String, id: String, status: String) async throws -> OrderModel {
        let body: [String: String] = ["status": status]
        let data = try JSONSerialization.data(withJSONObject: body)
        let endpoint = APIEndpoint(path: "api/orders/\(id)/status", method: .put, body: data)
        return try await network.request(endpoint, token: token)
    }

    public func updateOrderLR(
        token: String,
        id: String,
        lrNumber: String,
        transporter: String,
        vehicleNumber: String,
        lrNotes: String,
        fileDataUri: String?,
        fileName: String?,
        fileSize: String?
    ) async throws -> OrderModel {
        var body: [String: String] = [
            "lrNumber": lrNumber,
            "transporter": transporter,
            "vehicleNumber": vehicleNumber,
            "lrNotes": lrNotes
        ]

        if let uri = fileDataUri, !uri.isEmpty {
            body["lrFileUrl"] = uri
            body["lrFileName"] = fileName ?? "lr_receipt"
            body["lrFileSize"] = fileSize ?? ""
            let isoFormatter = ISO8601DateFormatter()
            body["lrUploadedAt"] = isoFormatter.string(from: Date())
        }

        let data = try JSONSerialization.data(withJSONObject: body)
        // 120-second timeout for large base64 LR document uploads up to 10-14 MB
        let endpoint = APIEndpoint(path: "api/orders/\(id)", method: .put, body: data, timeoutInterval: 120.0)
        return try await network.request(endpoint, token: token)
    }

    public func deleteOrderLR(token: String, id: String) async throws -> OrderModel {
        let body: [String: String] = [
            "lrNumber": "",
            "transporter": "",
            "vehicleNumber": "",
            "lrNotes": "",
            "lrFileUrl": "",
            "lrFileName": "",
            "lrFileSize": "",
            "lrUploadedAt": ""
        ]
        let data = try JSONSerialization.data(withJSONObject: body)
        let endpoint = APIEndpoint(path: "api/orders/\(id)", method: .put, body: data)
        return try await network.request(endpoint, token: token)
    }
}
