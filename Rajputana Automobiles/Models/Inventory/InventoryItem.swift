import Foundation

public struct InventoryItem: Codable, Identifiable, Hashable {
    public var id: String { _id ?? itemId ?? itemCode }
    public var mongoId: String { _id ?? itemId ?? id }

    public let _id: String?
    public let itemId: String?
    public let itemCode: String
    public let productName: String?
    public let itemName: String?

    public let primaryGroup: String?
    public let stockGroup: String?
    public let category: String?
    public let systemDomain: String?
    public let vehicleSegment: String?

    public let unit: String?
    public let stockLevel: Double?
    public let minThreshold: Double?
    public let status: String?

    public let unitPrice: Double?
    public let customerPrice: Double?
    public let dealerPrice: Double?
    public let retailPrice: Double?
    public let wholesalePrice: Double?
    public let closingValue: Double?
    public let gst: Int?

    public let warehouse: String?
    public let imageUrl: String?
    public let images: [String]?
    public let specifications: [String]?
    public let description: String?

    public init(
        _id: String? = nil,
        itemId: String? = nil,
        itemCode: String,
        productName: String? = nil,
        itemName: String? = nil,
        primaryGroup: String? = nil,
        stockGroup: String? = nil,
        category: String? = nil,
        systemDomain: String? = nil,
        vehicleSegment: String? = nil,
        unit: String? = nil,
        stockLevel: Double? = nil,
        minThreshold: Double? = nil,
        status: String? = nil,
        unitPrice: Double? = nil,
        customerPrice: Double? = nil,
        dealerPrice: Double? = nil,
        retailPrice: Double? = nil,
        wholesalePrice: Double? = nil,
        closingValue: Double? = nil,
        gst: Int? = nil,
        warehouse: String? = nil,
        imageUrl: String? = nil,
        images: [String]? = nil,
        specifications: [String]? = nil,
        description: String? = nil
    ) {
        self._id = _id
        self.itemId = itemId
        self.itemCode = itemCode
        self.productName = productName
        self.itemName = itemName
        self.primaryGroup = primaryGroup
        self.stockGroup = stockGroup
        self.category = category
        self.systemDomain = systemDomain
        self.vehicleSegment = vehicleSegment
        self.unit = unit
        self.stockLevel = stockLevel
        self.minThreshold = minThreshold
        self.status = status
        self.unitPrice = unitPrice
        self.customerPrice = customerPrice
        self.dealerPrice = dealerPrice
        self.retailPrice = retailPrice
        self.wholesalePrice = wholesalePrice
        self.closingValue = closingValue
        self.gst = gst
        self.warehouse = warehouse
        self.imageUrl = imageUrl
        self.images = images
        self.specifications = specifications
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case _id
        case itemId = "id"
        case itemCode, productName, itemName
        case primaryGroup, stockGroup, category, systemDomain, vehicleSegment
        case unit, stockLevel, minThreshold, status
        case unitPrice, customerPrice, dealerPrice, retailPrice, wholesalePrice, closingValue, gst
        case warehouse, imageUrl, images, specifications, description
    }

    public var displayName: String {
        if let p = productName, !p.isEmpty { return p }
        if let i = itemName, !i.isEmpty { return i }
        return itemCode
    }

    public var effectivePrice: Double {
        return dealerPrice ?? customerPrice ?? unitPrice ?? 0.0
    }

    public var effectiveStock: Double {
        return stockLevel ?? 0.0
    }

    public var isLowStock: Bool {
        return effectiveStock <= (minThreshold ?? 10.0)
    }

    public var bestImage: String {
        if let url = imageUrl, !url.isEmpty { return url }
        return images?.first ?? ""
    }

    public var categoryLine: String {
        var parts: [String] = []
        if let primary = primaryGroup, !primary.isEmpty { parts.append(primary) }
        if let stock = stockGroup, !stock.isEmpty && stock != primaryGroup { parts.append(stock) }
        return parts.joined(separator: " · ")
    }
}
