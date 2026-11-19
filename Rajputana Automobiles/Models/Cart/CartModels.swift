import Foundation

// ── DTOs for /api/cart Node contract ─────────────────────────
public struct CartApiItem: Codable, Identifiable {
    public var id: String
    public let name: String
    public let partNumber: String
    public let oemCode: String
    public let brand: String
    public let fits: String
    public let dealerPrice: Double
    public let boxPack: Int
    public var quantity: Int
    public var imageUrl: String

    enum CodingKeys: String, CodingKey {
        case id, name, partNumber, oemCode, brand, fits, dealerPrice, boxPack
        case quantity = "qty"
        case imageUrl
    }

    public init(
        id: String,
        name: String,
        partNumber: String,
        oemCode: String = "",
        brand: String = "",
        fits: String = "",
        dealerPrice: Double,
        boxPack: Int = 1,
        quantity: Int = 1,
        imageUrl: String = ""
    ) {
        self.id = id
        self.name = name
        self.partNumber = partNumber
        self.oemCode = oemCode
        self.brand = brand
        self.fits = fits
        self.dealerPrice = dealerPrice
        self.boxPack = boxPack
        self.quantity = quantity
        self.imageUrl = imageUrl
    }

    public var lineTotal: Double {
        return dealerPrice * Double(quantity)
    }
}

public struct CartApiRequest: Codable {
    public let customerIdentifier: String
    public let customerName: String
    public let items: [CartApiItem]

    public init(customerIdentifier: String, customerName: String, items: [CartApiItem]) {
        self.customerIdentifier = customerIdentifier
        self.customerName = customerName
        self.items = items
    }
}

public struct CartApiResponse: Codable {
    public let success: Bool?
    public let customerIdentifier: String?
    public let customerName: String?
    public let items: [CartApiItem]?
    public let message: String?
}

// ── Delivery Address Model ────────────────────────────────────
public struct DeliveryAddress: Codable, Identifiable {
    public var id: String = UUID().uuidString
    public var label: String
    public var isDefault: Bool
    public var recipientName: String
    public var line1: String
    public var line2: String
    public var city: String
    public var state: String
    public var pincode: String
    public var phone: String
    public var gstin: String?

    public init(
        id: String = UUID().uuidString,
        label: String = "Primary Workshop",
        isDefault: Bool = true,
        recipientName: String,
        line1: String,
        line2: String = "",
        city: String,
        state: String,
        pincode: String,
        phone: String,
        gstin: String? = nil
    ) {
        self.id = id
        self.label = label
        self.isDefault = isDefault
        self.recipientName = recipientName
        self.line1 = line1
        self.line2 = line2
        self.city = city
        self.state = state
        self.pincode = pincode
        self.phone = phone
        self.gstin = gstin
    }

    public var fullAddress: String {
        return [line1, line2, "\(city), \(state) - \(pincode)"].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

// ── UPI Payment Info Model ────────────────────────────────────
public struct UpiPaymentInfo {
    public let beneficiaryName: String = "Rajputana Automobiles"
    public let upiId: String = "rajputana.auto@icici"
    public let amount: Double
}

// ── Order Placement Request & Response (POST /api/orders) ─────
public struct PlaceOrderRequest: Codable {
    public let customerId: String?
    public let customerCode: String?
    public let customerName: String
    public let customerEmail: String?
    public let items: [PlaceOrderItemRequest]
    public let itemCount: Int
    public let subtotal: Double
    public let gst: Double
    public let total: Double
    public let shipping: PlaceOrderShippingRequest

    public init(
        customerId: String?,
        customerCode: String?,
        customerName: String,
        customerEmail: String?,
        items: [PlaceOrderItemRequest],
        itemCount: Int,
        subtotal: Double,
        gst: Double,
        total: Double,
        shipping: PlaceOrderShippingRequest
    ) {
        self.customerId = customerId
        self.customerCode = customerCode
        self.customerName = customerName
        self.customerEmail = customerEmail
        self.items = items
        self.itemCount = itemCount
        self.subtotal = subtotal
        self.gst = gst
        self.total = total
        self.shipping = shipping
    }
}

public struct PlaceOrderItemRequest: Codable {
    public let id: String
    public let itemCode: String
    public let name: String
    public let productName: String
    public let qty: Int
    public let rate: Double
    public let unitPrice: Double
    public let total: Double

    public init(id: String, itemCode: String, name: String, productName: String, qty: Int, rate: Double, unitPrice: Double, total: Double) {
        self.id = id
        self.itemCode = itemCode
        self.name = name
        self.productName = productName
        self.qty = qty
        self.rate = rate
        self.unitPrice = unitPrice
        self.total = total
    }
}

public struct PlaceOrderShippingRequest: Codable {
    public let name: String
    public let line: String
    public let city: String
    public let state: String
    public let pincode: String
    public let phone: String
    public let email: String?
    public let gstin: String?

    public init(name: String, line: String, city: String, state: String, pincode: String, phone: String, email: String? = nil, gstin: String? = nil) {
        self.name = name
        self.line = line
        self.city = city
        self.state = state
        self.pincode = pincode
        self.phone = phone
        self.email = email
        self.gstin = gstin
    }
}

public struct PlaceOrderResponse: Codable {
    public let _id: String?
    public let id: String?
    public let orderNumber: String?
    public let customerName: String?
    public let total: Double?
    public let status: String?
}
