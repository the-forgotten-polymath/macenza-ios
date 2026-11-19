import Foundation

public struct LedgerSummary: Codable, Identifiable {
    public var id: String {
        if !summaryId.isEmpty { return summaryId }
        if let c = code, !c.isEmpty { return c }
        if let p = partyName, !p.isEmpty { return p }
        return name ?? UUID().uuidString
    }

    public let summaryId: String
    public let customerId: String?
    public let code: String?
    public let partyName: String?
    public let name: String?
    public let city: String?
    public let state: String?
    public let totalAmount: Double?
    public let paidAmount: Double?
    public let outstandingBalance: Double?
    public let closingBalance: Double?
    public let openingBalance: Double?
    public let billCount: Int?
    public let phone: String?
    public let gstin: String?

    enum CodingKeys: String, CodingKey {
        case summaryId = "id"
        case customerId, code, partyName, name, city, state
        case totalAmount, paidAmount, outstandingBalance, closingBalance, openingBalance
        case billCount, phone, gstin
    }

    public var effectivePartyName: String {
        if let p = partyName, !p.isEmpty { return p }
        if let n = name, !n.isEmpty { return n }
        return code ?? "Party"
    }

    public var effectiveBalance: Double {
        return closingBalance ?? outstandingBalance ?? 0.0
    }
}

public struct LedgerCustomer: Codable {
    public let id: String?
    public let name: String?
    public let partyName: String?
    public let code: String?
    public let city: String?
    public let address: String?
    public let phone: String?
    public let email: String?
    public let gstin: String?
    public let creditLimit: Double?
    public let openingBalance: Double?
    public let totalAmount: Double?
    public let paidAmount: Double?
    public let outstandingBalance: Double?
    public let closingBalance: Double?
    public let billCount: Int?
}

public struct LedgerPeriod: Codable {
    public let fromDate: String?
    public let toDate: String?
}

public struct LedgerResponse: Codable {
    public let customer: LedgerCustomer?
    public let period: LedgerPeriod?
    public let openingBalance: Double?
    public let closingBalance: Double?
    public let currentDebitTotal: Double?
    public let currentCreditTotal: Double?
    public let outstandingBalance: Double?
    public let billsReceivable: [BillReceivable]?
    public let ledgerVouchers: [LedgerVoucher]?

    public var totalDebits: Double? { currentDebitTotal }
    public var totalCredits: Double? { currentCreditTotal }
    public var periodFrom: String? { period?.fromDate }
    public var periodTo: String? { period?.toDate }
}

public struct BillReceivable: Codable, Identifiable {
    public var id: String { refNo.isEmpty ? (billId.isEmpty ? UUID().uuidString : billId) : refNo }

    public let billId: String
    public let date: String?
    public let refNo: String
    public let partyName: String?
    public let pendingAmount: Double?
    public let dueOn: String?
    public let overdueDays: Int?
    public let billAmount: Double?
    public let paidAmount: Double?
    public let pdfUrl: String?

    enum CodingKeys: String, CodingKey {
        case billId = "id"
        case date, refNo, partyName, pendingAmount, dueOn, overdueDays, billAmount, paidAmount, pdfUrl
    }
}

public struct LedgerVoucher: Codable, Identifiable {
    public var id: String { voucherNumber.isEmpty ? (voucherId.isEmpty ? UUID().uuidString : voucherId) : voucherNumber }

    public let voucherId: String
    public let date: String?
    public let voucherType: String?
    public let voucherNumber: String
    public let particulars: String?
    public let debit: Double?
    public let credit: Double?
    public let amount: Double?
    public let runningBalance: Double?
    public let pdfUrl: String?

    enum CodingKeys: String, CodingKey {
        case voucherId = "id"
        case date, voucherType, voucherNumber, particulars, debit, credit, amount, runningBalance, pdfUrl
    }
}
