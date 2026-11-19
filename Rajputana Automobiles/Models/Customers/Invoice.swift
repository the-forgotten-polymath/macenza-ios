import Foundation

public struct Invoice: Codable, Identifiable {
    public var id: String {
        if !invoiceNumber.isEmpty { return invoiceNumber }
        if let v = voucherNumber, !v.isEmpty { return v }
        if let i = invoiceId, !i.isEmpty { return i }
        return UUID().uuidString
    }

    public let invoiceId: String?
    public let invoiceNumber: String
    public let voucherNumber: String?
    public let voucherType: String?
    public let customerName: String?
    public let party: String?
    public let customerCode: String?
    public let amount: Double?
    public let subtotal: Double?
    public let cgst: Double?
    public let sgst: Double?
    public let igst: Double?
    public let roundOff: Double?
    public let taxAmount: Double?
    public let netAmount: Double?
    public let grandTotal: Double?
    public let status: String?
    public let date: String?
    public let dueDate: String?
    public let buyerAddress: String?
    public let buyerGstin: String?
    public let buyerPhone: String?
    public let stateName: String?
    public let placeOfSupply: String?
    public let pdfUrl: String?
    public let items: [InvoiceItem]?

    public var effectiveCustomerName: String {
        customerName ?? party ?? "Customer"
    }
    public var effectiveParty: String {
        party ?? customerName ?? ""
    }
    public var effectiveStatus: String {
        status ?? "Paid"
    }
    public var effectiveDate: String {
        date ?? ""
    }
    public var effectiveDueDate: String {
        dueDate ?? date ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case invoiceId = "id"
        case invoiceNumber, voucherNumber, voucherType
        case customerName, party, customerCode
        case amount, subtotal, cgst, sgst, igst, roundOff, taxAmount, netAmount, grandTotal
        case status, date, dueDate, buyerAddress, buyerGstin, buyerPhone, stateName, placeOfSupply, pdfUrl, items
    }

    public init(
        invoiceId: String? = nil,
        invoiceNumber: String,
        voucherNumber: String? = nil,
        voucherType: String? = nil,
        customerName: String? = nil,
        party: String? = nil,
        customerCode: String? = nil,
        amount: Double? = nil,
        subtotal: Double? = nil,
        cgst: Double? = nil,
        sgst: Double? = nil,
        igst: Double? = nil,
        roundOff: Double? = nil,
        taxAmount: Double? = nil,
        netAmount: Double? = nil,
        grandTotal: Double? = nil,
        status: String? = nil,
        date: String? = nil,
        dueDate: String? = nil,
        buyerAddress: String? = nil,
        buyerGstin: String? = nil,
        buyerPhone: String? = nil,
        stateName: String? = nil,
        placeOfSupply: String? = nil,
        pdfUrl: String? = nil,
        items: [InvoiceItem]? = nil
    ) {
        self.invoiceId = invoiceId
        self.invoiceNumber = invoiceNumber
        self.voucherNumber = voucherNumber
        self.voucherType = voucherType
        self.customerName = customerName
        self.party = party
        self.customerCode = customerCode
        self.amount = amount
        self.subtotal = subtotal
        self.cgst = cgst
        self.sgst = sgst
        self.igst = igst
        self.roundOff = roundOff
        self.taxAmount = taxAmount
        self.netAmount = netAmount
        self.grandTotal = grandTotal
        self.status = status
        self.date = date
        self.dueDate = dueDate
        self.buyerAddress = buyerAddress
        self.buyerGstin = buyerGstin
        self.buyerPhone = buyerPhone
        self.stateName = stateName
        self.placeOfSupply = placeOfSupply
        self.pdfUrl = pdfUrl
        self.items = items
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.invoiceId = try? container.decodeIfPresent(String.self, forKey: .invoiceId)
        self.invoiceNumber = (try? container.decodeIfPresent(String.self, forKey: .invoiceNumber))
            ?? (try? container.decodeIfPresent(String.self, forKey: .voucherNumber))
            ?? ""
        self.voucherNumber = try? container.decodeIfPresent(String.self, forKey: .voucherNumber)
        self.voucherType = try? container.decodeIfPresent(String.self, forKey: .voucherType)
        self.customerName = try? container.decodeIfPresent(String.self, forKey: .customerName)
        self.party = try? container.decodeIfPresent(String.self, forKey: .party)
        self.customerCode = try? container.decodeIfPresent(String.self, forKey: .customerCode)

        // Tolerant numbers (can be Double, Int, or formatted String)
        self.amount = Self.decodeTolerantDouble(container, key: .amount)
        self.subtotal = Self.decodeTolerantDouble(container, key: .subtotal)
        self.cgst = Self.decodeTolerantDouble(container, key: .cgst)
        self.sgst = Self.decodeTolerantDouble(container, key: .sgst)
        self.igst = Self.decodeTolerantDouble(container, key: .igst)
        self.roundOff = Self.decodeTolerantDouble(container, key: .roundOff)
        self.taxAmount = Self.decodeTolerantDouble(container, key: .taxAmount)
        self.netAmount = Self.decodeTolerantDouble(container, key: .netAmount)
        self.grandTotal = Self.decodeTolerantDouble(container, key: .grandTotal)

        self.status = try? container.decodeIfPresent(String.self, forKey: .status)
        self.date = try? container.decodeIfPresent(String.self, forKey: .date)
        self.dueDate = try? container.decodeIfPresent(String.self, forKey: .dueDate)
        self.buyerAddress = try? container.decodeIfPresent(String.self, forKey: .buyerAddress)
        self.buyerGstin = try? container.decodeIfPresent(String.self, forKey: .buyerGstin)
        self.buyerPhone = try? container.decodeIfPresent(String.self, forKey: .buyerPhone)
        self.stateName = try? container.decodeIfPresent(String.self, forKey: .stateName)
        self.placeOfSupply = try? container.decodeIfPresent(String.self, forKey: .placeOfSupply)
        self.pdfUrl = try? container.decodeIfPresent(String.self, forKey: .pdfUrl)
        self.items = try? container.decodeIfPresent([InvoiceItem].self, forKey: .items)
    }

    private static func decodeTolerantDouble(_ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Double? {
        if let d = try? container.decodeIfPresent(Double.self, forKey: key) { return d }
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return Double(i) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            let cleaned = s.replacingOccurrences(of: "₹", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            return Double(cleaned)
        }
        return nil
    }

    public var effectiveAmount: Double {
        return amount ?? netAmount ?? ((subtotal ?? 0) + (taxAmount ?? 0))
    }

    public var effectivePartyName: String {
        return customerName ?? party ?? "Customer"
    }
}

public struct InvoiceItem: Codable, Identifiable {
    public var id: String { "\(slNo ?? 1)_\(partNo ?? UUID().uuidString)" }
    public let slNo: Int?
    public let description: String?
    public let partNo: String?
    public let qty: Int?
    public let rate: Double?
    public let amount: Double?
    public let discount: String?
    public let discountPercent: Double?
    public let discountAmount: Double?
    public let unit: String?
    public let hsnSac: String?
    public let gstRate: String?
    public let taxableAmount: Double?
    public let cgstAmount: Double?
    public let sgstAmount: Double?
    public let igstAmount: Double?

    enum CodingKeys: String, CodingKey {
        case slNo, description, partNo, qty, rate, amount
        case itemName, name, itemCode, partNumber, quantity
        case discount, discountPercent, discountAmount, unit, hsnSac, gstRate
        case taxableAmount, cgstAmount, sgstAmount, igstAmount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let s = try? container.decodeIfPresent(Int.self, forKey: .slNo) {
            self.slNo = s
        } else if let sStr = try? container.decodeIfPresent(String.self, forKey: .slNo), let s = Int(sStr) {
            self.slNo = s
        } else {
            self.slNo = 1
        }

        self.description = (try? container.decodeIfPresent(String.self, forKey: .description))
            ?? (try? container.decodeIfPresent(String.self, forKey: .itemName))
            ?? (try? container.decodeIfPresent(String.self, forKey: .name))

        self.partNo = (try? container.decodeIfPresent(String.self, forKey: .partNo))
            ?? (try? container.decodeIfPresent(String.self, forKey: .itemCode))
            ?? (try? container.decodeIfPresent(String.self, forKey: .partNumber))
            ?? "—"

        if let q = try? container.decodeIfPresent(Int.self, forKey: .qty) {
            self.qty = q
        } else if let q = try? container.decodeIfPresent(Int.self, forKey: .quantity) {
            self.qty = q
        } else if let qStr = try? container.decodeIfPresent(String.self, forKey: .qty) {
            let digits = qStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            self.qty = Int(digits) ?? 1
        } else {
            self.qty = 1
        }

        if let r = try? container.decodeIfPresent(Double.self, forKey: .rate) {
            self.rate = r
        } else if let rStr = try? container.decodeIfPresent(String.self, forKey: .rate) {
            let cleaned = rStr.replacingOccurrences(of: "₹", with: "").replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
            self.rate = Double(cleaned)
        } else {
            self.rate = 0.0
        }

        if let a = try? container.decodeIfPresent(Double.self, forKey: .amount) {
            self.amount = a
        } else if let aStr = try? container.decodeIfPresent(String.self, forKey: .amount) {
            let cleaned = aStr.replacingOccurrences(of: "₹", with: "").replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
            self.amount = Double(cleaned)
        } else {
            self.amount = Double(self.qty ?? 1) * (self.rate ?? 0.0)
        }

        self.discount = try? container.decodeIfPresent(String.self, forKey: .discount)
        self.discountPercent = try? container.decodeIfPresent(Double.self, forKey: .discountPercent)
        self.discountAmount = try? container.decodeIfPresent(Double.self, forKey: .discountAmount)
        self.unit = try? container.decodeIfPresent(String.self, forKey: .unit)
        self.hsnSac = try? container.decodeIfPresent(String.self, forKey: .hsnSac)
        self.gstRate = try? container.decodeIfPresent(String.self, forKey: .gstRate)
        self.taxableAmount = try? container.decodeIfPresent(Double.self, forKey: .taxableAmount)
        self.cgstAmount = try? container.decodeIfPresent(Double.self, forKey: .cgstAmount)
        self.sgstAmount = try? container.decodeIfPresent(Double.self, forKey: .sgstAmount)
        self.igstAmount = try? container.decodeIfPresent(Double.self, forKey: .igstAmount)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(slNo, forKey: .slNo)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(partNo, forKey: .partNo)
        try container.encodeIfPresent(qty, forKey: .qty)
        try container.encodeIfPresent(rate, forKey: .rate)
        try container.encodeIfPresent(amount, forKey: .amount)
        try container.encodeIfPresent(discount, forKey: .discount)
        try container.encodeIfPresent(unit, forKey: .unit)
        try container.encodeIfPresent(hsnSac, forKey: .hsnSac)
        try container.encodeIfPresent(gstRate, forKey: .gstRate)
    }
}
