import Foundation

public struct OrderModel: Codable, Identifiable, Hashable {
    public var id: String {
        if let oid = orderId, !oid.trimmingCharacters(in: .whitespaces).isEmpty { return oid }
        if let num = orderNumber, !num.trimmingCharacters(in: .whitespaces).isEmpty { return num }
        if let mid = _id, !mid.trimmingCharacters(in: .whitespaces).isEmpty { return mid }
        return UUID().uuidString
    }

    public var targetIdForApi: String {
        if let oid = orderId, !oid.trimmingCharacters(in: .whitespaces).isEmpty { return oid }
        if let num = orderNumber, !num.trimmingCharacters(in: .whitespaces).isEmpty { return num }
        if let mid = _id, !mid.trimmingCharacters(in: .whitespaces).isEmpty { return mid }
        return ""
    }

    public let _id: String?
    public let orderId: String?
    public let orderNumber: String?

    public let customerName: String?
    public let customerCode: String?
    public let customerEmail: String?

    public let date: String?
    public let status: String?

    public let itemCount: Int?
    public let subtotal: Double?
    public let gst: Double?
    public let total: Double?

    public let shipping: ShippingInfo?
    public let items: [OrderItem]?

    // ── Lorry Receipt (LR) ────────────────────────────────────
    public var lrNumber: String?
    public var lrFileUrl: String?
    public var lrFileName: String?
    public var lrFileSize: String?
    public var lrUploadedAt: String?
    public var transporter: String?
    public var vehicleNumber: String?
    public var lrNotes: String?

    public let createdAt: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case _id
        case orderId = "id"
        case orderNumber
        case customerName, customerCode, customerEmail
        case date, orderDate
        case status, orderStatus
        case itemCount, totalItems
        case subtotal
        case gst
        case total, amount, grandTotal, totalAmount
        case shipping
        case items, orderItems, lineItems, products, invoiceItems
        case lrNumber, lrFileUrl, lrFileName, lrFileSize, lrUploadedAt, transporter, vehicleNumber, lrNotes
        case createdAt, updatedAt
    }

    public init(
        _id: String? = nil,
        orderId: String? = nil,
        orderNumber: String? = nil,
        customerName: String? = nil,
        customerCode: String? = nil,
        customerEmail: String? = nil,
        date: String? = nil,
        status: String? = nil,
        itemCount: Int? = nil,
        subtotal: Double? = nil,
        gst: Double? = nil,
        total: Double? = nil,
        shipping: ShippingInfo? = nil,
        items: [OrderItem]? = nil,
        lrNumber: String? = nil,
        lrFileUrl: String? = nil,
        lrFileName: String? = nil,
        lrFileSize: String? = nil,
        lrUploadedAt: String? = nil,
        transporter: String? = nil,
        vehicleNumber: String? = nil,
        lrNotes: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self._id = _id
        self.orderId = orderId
        self.orderNumber = orderNumber
        self.customerName = customerName
        self.customerCode = customerCode
        self.customerEmail = customerEmail
        self.date = date
        self.status = status
        self.itemCount = itemCount
        self.subtotal = subtotal
        self.gst = gst
        self.total = total
        self.shipping = shipping
        self.items = items
        self.lrNumber = lrNumber
        self.lrFileUrl = lrFileUrl
        self.lrFileName = lrFileName
        self.lrFileSize = lrFileSize
        self.lrUploadedAt = lrUploadedAt
        self.transporter = transporter
        self.vehicleNumber = vehicleNumber
        self.lrNotes = lrNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self._id = try? container.decodeIfPresent(String.self, forKey: ._id)
        self.orderId = try? container.decodeIfPresent(String.self, forKey: .orderId)
        self.orderNumber = try? container.decodeIfPresent(String.self, forKey: .orderNumber)
        self.customerName = try? container.decodeIfPresent(String.self, forKey: .customerName)
        self.customerCode = try? container.decodeIfPresent(String.self, forKey: .customerCode)
        self.customerEmail = try? container.decodeIfPresent(String.self, forKey: .customerEmail)

        if let d = try? container.decodeIfPresent(String.self, forKey: .date) {
            self.date = d
        } else if let d = try? container.decodeIfPresent(String.self, forKey: .orderDate) {
            self.date = d
        } else {
            self.date = nil
        }

        if let s = try? container.decodeIfPresent(String.self, forKey: .status) {
            self.status = s
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .orderStatus) {
            self.status = s
        } else {
            self.status = nil
        }

        if let count = try? container.decodeIfPresent(Int.self, forKey: .itemCount) {
            self.itemCount = count
        } else if let count = try? container.decodeIfPresent(Int.self, forKey: .totalItems) {
            self.itemCount = count
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .itemCount), let count = Int(str) {
            self.itemCount = count
        } else if let dbl = try? container.decodeIfPresent(Double.self, forKey: .itemCount) {
            self.itemCount = Int(dbl)
        } else {
            self.itemCount = nil
        }

        if let val = try? container.decodeIfPresent(Double.self, forKey: .subtotal) {
            self.subtotal = val
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .subtotal), let val = Double(str) {
            self.subtotal = val
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .subtotal) {
            self.subtotal = Double(intVal)
        } else {
            self.subtotal = nil
        }

        if let val = try? container.decodeIfPresent(Double.self, forKey: .gst) {
            self.gst = val
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .gst), let val = Double(str) {
            self.gst = val
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .gst) {
            self.gst = Double(intVal)
        } else {
            self.gst = nil
        }

        if let val = try? container.decodeIfPresent(Double.self, forKey: .total) {
            self.total = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .amount) {
            self.total = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .grandTotal) {
            self.total = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .totalAmount) {
            self.total = val
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .total), let val = Double(str) {
            self.total = val
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .total) {
            self.total = Double(intVal)
        } else {
            self.total = nil
        }

        self.shipping = try? container.decodeIfPresent(ShippingInfo.self, forKey: .shipping)

        if let it = try? container.decodeIfPresent([OrderItem].self, forKey: .items) {
            self.items = it
        } else if let it = try? container.decodeIfPresent([OrderItem].self, forKey: .orderItems) {
            self.items = it
        } else if let it = try? container.decodeIfPresent([OrderItem].self, forKey: .lineItems) {
            self.items = it
        } else if let it = try? container.decodeIfPresent([OrderItem].self, forKey: .products) {
            self.items = it
        } else if let it = try? container.decodeIfPresent([OrderItem].self, forKey: .invoiceItems) {
            self.items = it
        } else {
            self.items = nil
        }

        self.lrNumber = try? container.decodeIfPresent(String.self, forKey: .lrNumber)
        self.lrFileUrl = try? container.decodeIfPresent(String.self, forKey: .lrFileUrl)
        self.lrFileName = try? container.decodeIfPresent(String.self, forKey: .lrFileName)
        self.lrFileSize = try? container.decodeIfPresent(String.self, forKey: .lrFileSize)
        self.lrUploadedAt = try? container.decodeIfPresent(String.self, forKey: .lrUploadedAt)
        self.transporter = try? container.decodeIfPresent(String.self, forKey: .transporter)
        self.vehicleNumber = try? container.decodeIfPresent(String.self, forKey: .vehicleNumber)
        self.lrNotes = try? container.decodeIfPresent(String.self, forKey: .lrNotes)

        self.createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try? container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(_id, forKey: ._id)
        try container.encodeIfPresent(orderId, forKey: .orderId)
        try container.encodeIfPresent(orderNumber, forKey: .orderNumber)
        try container.encodeIfPresent(customerName, forKey: .customerName)
        try container.encodeIfPresent(customerCode, forKey: .customerCode)
        try container.encodeIfPresent(customerEmail, forKey: .customerEmail)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(itemCount, forKey: .itemCount)
        try container.encodeIfPresent(subtotal, forKey: .subtotal)
        try container.encodeIfPresent(gst, forKey: .gst)
        try container.encodeIfPresent(total, forKey: .total)
        try container.encodeIfPresent(shipping, forKey: .shipping)
        try container.encodeIfPresent(items, forKey: .items)
        try container.encodeIfPresent(lrNumber, forKey: .lrNumber)
        try container.encodeIfPresent(lrFileUrl, forKey: .lrFileUrl)
        try container.encodeIfPresent(lrFileName, forKey: .lrFileName)
        try container.encodeIfPresent(lrFileSize, forKey: .lrFileSize)
        try container.encodeIfPresent(lrUploadedAt, forKey: .lrUploadedAt)
        try container.encodeIfPresent(transporter, forKey: .transporter)
        try container.encodeIfPresent(vehicleNumber, forKey: .vehicleNumber)
        try container.encodeIfPresent(lrNotes, forKey: .lrNotes)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    public var effectiveAmount: Double {
        return total ?? subtotal ?? 0.0
    }

    public var effectiveDate: String {
        return date ?? createdAt ?? ""
    }

    public var displayOrderNumber: String {
        if let num = orderNumber, !num.isEmpty { return num }
        if let oid = orderId, !oid.isEmpty { return oid }
        return "ORD-N/A"
    }

    public var displayCustomerName: String {
        return customerName ?? "Customer"
    }

    public var displayStatus: String {
        return status ?? "Confirmed"
    }

    public var displayItemCount: Int {
        return itemCount ?? items?.count ?? 0
    }

    public var canManageLr: Bool {
        let s = displayStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return s == "approved" || s == "synced" || s == "dispatched" || s == "delivered"
    }

    public var hasLr: Bool {
        return !(lrNumber?.isEmpty ?? true) || !(lrFileUrl?.isEmpty ?? true)
    }

    public var hasLrDocument: Bool {
        return !(lrFileUrl?.isEmpty ?? true)
    }

    public var lrLabel: String {
        if let lr = lrNumber, !lr.trimmingCharacters(in: .whitespaces).isEmpty {
            return lr
        }
        return "Pending"
    }

    public var displayCity: String {
        if let city = shipping?.city, !city.trimmingCharacters(in: .whitespaces).isEmpty {
            return city
        }
        return "—"
    }
}

public struct ShippingInfo: Codable, Hashable {
    public let name: String?
    public let line: String?
    public let city: String?
    public let state: String?
    public let pincode: String?
    public let phone: String?
    public let email: String?
    public let gstin: String?

    public init(
        name: String? = nil,
        line: String? = nil,
        city: String? = nil,
        state: String? = nil,
        pincode: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        gstin: String? = nil
    ) {
        self.name = name
        self.line = line
        self.city = city
        self.state = state
        self.pincode = pincode
        self.phone = phone
        self.email = email
        self.gstin = gstin
    }

    public var fullAddress: String {
        return [line, city, state, pincode].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

public struct OrderItem: Codable, Identifiable, Hashable {
    public var id: String { itemId ?? itemCode ?? UUID().uuidString }

    public let itemId: String?
    public let itemCode: String?
    public let name: String?
    public let productName: String?
    public let category: String?
    public let qty: Int?
    public let rate: Double?
    public let unitPrice: Double?
    public let total: Double?

    enum CodingKeys: String, CodingKey {
        case itemId = "id"
        case itemCode, partNumber, skuCode, productCode, code
        case name, productName, itemName, description, title, product
        case category, group
        case qty, quantity, orderedQty, count
        case rate, price, sellingPrice, unitRate
        case unitPrice, dealerPrice, pricePerUnit, mrp
        case total, lineTotal, amount, itemTotal, netAmount
    }

    public init(
        itemId: String? = nil,
        itemCode: String? = nil,
        name: String? = nil,
        productName: String? = nil,
        category: String? = nil,
        qty: Int? = nil,
        rate: Double? = nil,
        unitPrice: Double? = nil,
        total: Double? = nil
    ) {
        self.itemId = itemId
        self.itemCode = itemCode
        self.name = name
        self.productName = productName
        self.category = category
        self.qty = qty
        self.rate = rate
        self.unitPrice = unitPrice
        self.total = total
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.itemId = try? container.decodeIfPresent(String.self, forKey: .itemId)

        // itemCode
        if let v = try? container.decodeIfPresent(String.self, forKey: .itemCode) {
            self.itemCode = v
        } else if let v = try? container.decodeIfPresent(String.self, forKey: .partNumber) {
            self.itemCode = v
        } else if let v = try? container.decodeIfPresent(String.self, forKey: .skuCode) {
            self.itemCode = v
        } else if let v = try? container.decodeIfPresent(String.self, forKey: .productCode) {
            self.itemCode = v
        } else if let v = try? container.decodeIfPresent(String.self, forKey: .code) {
            self.itemCode = v
        } else {
            self.itemCode = nil
        }

        // productName
        if let v = try? container.decodeIfPresent(String.self, forKey: .productName) {
            self.productName = v
        } else if let v = try? container.decodeIfPresent(String.self, forKey: .itemName) {
            self.productName = v
        } else if let v = try? container.decodeIfPresent(String.self, forKey: .description) {
            self.productName = v
        } else if let v = try? container.decodeIfPresent(String.self, forKey: .title) {
            self.productName = v
        } else if let v = try? container.decodeIfPresent(String.self, forKey: .product) {
            self.productName = v
        } else {
            self.productName = nil
        }

        self.name = try? container.decodeIfPresent(String.self, forKey: .name)

        if let v = try? container.decodeIfPresent(String.self, forKey: .category) {
            self.category = v
        } else if let v = try? container.decodeIfPresent(String.self, forKey: .group) {
            self.category = v
        } else {
            self.category = nil
        }

        // qty
        if let v = try? container.decodeIfPresent(Int.self, forKey: .qty) {
            self.qty = v
        } else if let v = try? container.decodeIfPresent(Int.self, forKey: .quantity) {
            self.qty = v
        } else if let v = try? container.decodeIfPresent(Int.self, forKey: .orderedQty) {
            self.qty = v
        } else if let v = try? container.decodeIfPresent(Int.self, forKey: .count) {
            self.qty = v
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .qty), let v = Int(s) {
            self.qty = v
        } else if let d = try? container.decodeIfPresent(Double.self, forKey: .qty) {
            self.qty = Int(d)
        } else {
            self.qty = nil
        }

        // rate
        if let v = try? container.decodeIfPresent(Double.self, forKey: .rate) {
            self.rate = v
        } else if let v = try? container.decodeIfPresent(Double.self, forKey: .price) {
            self.rate = v
        } else if let v = try? container.decodeIfPresent(Double.self, forKey: .sellingPrice) {
            self.rate = v
        } else if let v = try? container.decodeIfPresent(Double.self, forKey: .unitRate) {
            self.rate = v
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .rate), let v = Double(s) {
            self.rate = v
        } else if let i = try? container.decodeIfPresent(Int.self, forKey: .rate) {
            self.rate = Double(i)
        } else {
            self.rate = nil
        }

        // unitPrice
        if let v = try? container.decodeIfPresent(Double.self, forKey: .unitPrice) {
            self.unitPrice = v
        } else if let v = try? container.decodeIfPresent(Double.self, forKey: .dealerPrice) {
            self.unitPrice = v
        } else if let v = try? container.decodeIfPresent(Double.self, forKey: .pricePerUnit) {
            self.unitPrice = v
        } else if let v = try? container.decodeIfPresent(Double.self, forKey: .mrp) {
            self.unitPrice = v
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .unitPrice), let v = Double(s) {
            self.unitPrice = v
        } else if let i = try? container.decodeIfPresent(Int.self, forKey: .unitPrice) {
            self.unitPrice = Double(i)
        } else {
            self.unitPrice = nil
        }

        // total
        if let v = try? container.decodeIfPresent(Double.self, forKey: .total) {
            self.total = v
        } else if let v = try? container.decodeIfPresent(Double.self, forKey: .lineTotal) {
            self.total = v
        } else if let v = try? container.decodeIfPresent(Double.self, forKey: .amount) {
            self.total = v
        } else if let v = try? container.decodeIfPresent(Double.self, forKey: .itemTotal) {
            self.total = v
        } else if let v = try? container.decodeIfPresent(Double.self, forKey: .netAmount) {
            self.total = v
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .total), let v = Double(s) {
            self.total = v
        } else if let i = try? container.decodeIfPresent(Int.self, forKey: .total) {
            self.total = Double(i)
        } else {
            self.total = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(itemId, forKey: .itemId)
        try container.encodeIfPresent(itemCode, forKey: .itemCode)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(productName, forKey: .productName)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(qty, forKey: .qty)
        try container.encodeIfPresent(rate, forKey: .rate)
        try container.encodeIfPresent(unitPrice, forKey: .unitPrice)
        try container.encodeIfPresent(total, forKey: .total)
    }

    public var effectiveCode: String {
        return itemCode ?? itemId ?? "—"
    }

    public var displayName: String {
        return productName ?? name ?? itemCode ?? "Item"
    }

    public var effectiveRate: Double {
        return unitPrice ?? rate ?? 0.0
    }

    public var effectiveQuantity: Int {
        return qty ?? 1
    }

    public var lineTotal: Double {
        return total ?? (effectiveRate * Double(effectiveQuantity))
    }
}
