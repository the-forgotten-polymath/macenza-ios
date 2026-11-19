import Foundation

public final class CartService {
    public static let shared = CartService()
    private let network = NetworkService.shared

    private init() {}

    public func fetchCart(token: String, identifier: String) async throws -> [CartApiItem] {
        let endpoint = APIEndpoint(
            path: "api/cart",
            method: .get,
            queryItems: [URLQueryItem(name: "identifier", value: identifier)]
        )
        let response: CartApiResponse = try await network.request(endpoint, token: token)
        return response.items ?? []
    }

    public func saveCart(token: String, identifier: String, customerName: String, items: [CartApiItem]) async throws {
        let body = CartApiRequest(customerIdentifier: identifier, customerName: customerName, items: items)
        let data = try JSONEncoder().encode(body)
        let endpoint = APIEndpoint(path: "api/cart", method: .put, body: data)
        let _: CartApiResponse = try await network.request(endpoint, token: token)
    }

    public func clearCart(token: String, identifier: String) async throws {
        let endpoint = APIEndpoint(
            path: "api/cart",
            method: .delete,
            queryItems: [URLQueryItem(name: "identifier", value: identifier)]
        )
        let _: CartApiResponse? = try? await network.request(endpoint, token: token)
    }

    public func placeOrder(
        token: String,
        session: AuthSession,
        items: [CartApiItem],
        shipping: DeliveryAddress
    ) async throws -> PlaceOrderResponse {
        let orderItems = items.map { item in
            PlaceOrderItemRequest(
                id: item.id,
                itemCode: item.partNumber,
                name: item.name,
                productName: item.name,
                qty: item.quantity,
                rate: item.dealerPrice,
                unitPrice: item.dealerPrice,
                total: item.lineTotal
            )
        }

        let subtotal = items.reduce(0.0) { $0 + $1.lineTotal }
        let gst = round((subtotal * 0.18) * 100) / 100.0
        let total = subtotal + gst

        let shippingReq = PlaceOrderShippingRequest(
            name: shipping.recipientName,
            line: "\(shipping.line1) \(shipping.line2)".trimmingCharacters(in: .whitespaces),
            city: shipping.city,
            state: shipping.state,
            pincode: shipping.pincode,
            phone: shipping.phone,
            email: session.customerEmail,
            gstin: shipping.gstin ?? session.gstin
        )

        let req = PlaceOrderRequest(
            customerId: session.userId,
            customerCode: session.customerCode,
            customerName: session.name,
            customerEmail: session.customerEmail,
            items: orderItems,
            itemCount: items.count,
            subtotal: subtotal,
            gst: gst,
            total: total,
            shipping: shippingReq
        )

        let data = try JSONEncoder().encode(req)

        // Custom ERP headers matching Android PlaceOrderApi contract exactly
        let encodedCustomerName = session.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? session.name
        let headers: [String: String] = [
            "Accept": "application/json",
            "X-ERP-Client-Version": "1.4.0",
            "x-user-role": session.backendRole.isEmpty ? "customer" : session.backendRole,
            "x-customer-id": session.effectiveCustomerIdentifier,
            "x-customer-name": encodedCustomerName
        ]

        let endpoint = APIEndpoint(
            path: "api/orders",
            method: .post,
            headers: headers,
            body: data
        )

        let response: PlaceOrderResponse = try await network.request(endpoint, token: token)

        // Clear cart on successful order placement (best effort)
        Task {
            try? await self.clearCart(token: token, identifier: session.effectiveCustomerIdentifier)
        }

        return response
    }
}
