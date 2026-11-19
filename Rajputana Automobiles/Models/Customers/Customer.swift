import Foundation

public struct Customer: Codable, Identifiable {
    public var id: String { _id ?? customerId ?? code }

    public let _id: String?
    public let customerId: String?
    public let code: String
    public let name: String
    public let companyId: String?
    public let tallyLedgerName: String?
    public let group: String?
    public let address: String?
    public let city: String?
    public let state: String?
    public let country: String?
    public let pincode: String?
    public let phone: String?
    public let email: String?
    public let gstin: String?
    public let creditLimit: Double?
    public let paymentTerms: String?
    public let outstandingBalance: Double?
    public let balanceType: String?
    public let status: String?
    public let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case _id
        case customerId = "id"
        case code, name, companyId, tallyLedgerName, group
        case address, city, state, country, pincode, phone, email, gstin
        case creditLimit, paymentTerms, outstandingBalance, balanceType, status, avatarUrl
    }

    public var effectiveBalance: Double {
        return outstandingBalance ?? 0.0
    }
}

public struct CustomerDetailModel: Codable {
    public let _id: String?
    public let id: String?
    public let code: String
    public let name: String
    public let tallyLedgerName: String?
    public let group: String?
    public let category: String?
    public let address: String?
    public let city: String?
    public let state: String?
    public let country: String?
    public let pincode: String?
    public let phone: String?
    public let email: String?
    public let gstin: String?
    public let bankName: String?
    public let bankAccount: String?
    public let bankIfsc: String?
    public let bankBranch: String?
    public let creditLimit: Double?
    public let paymentTerms: String?
    public let outstandingBalance: Double?
    public let balanceType: String?
    public let status: String?
    public let priceTier: String?
    public let vehicleSegmentAccess: String?
    public let allowedVehicleSegments: [String]?
    public let enableMobileApp: Bool?
    public let avatarUrl: String?
    public let avatar: String?

    public var effectiveId: String {
        return id ?? _id ?? code
    }

    public var fullAddress: String {
        let parts = [address, city, state, pincode].compactMap { $0 }.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return parts.joined(separator: ", ")
    }

    public var hasBankingDetails: Bool {
        return [bankName, bankAccount, bankIfsc, bankBranch]
            .compactMap { $0 }
            .contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    public init(
        _id: String? = nil,
        id: String? = nil,
        code: String,
        name: String,
        tallyLedgerName: String? = nil,
        group: String? = nil,
        category: String? = nil,
        address: String? = nil,
        city: String? = nil,
        state: String? = nil,
        country: String? = nil,
        pincode: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        gstin: String? = nil,
        bankName: String? = nil,
        bankAccount: String? = nil,
        bankIfsc: String? = nil,
        bankBranch: String? = nil,
        creditLimit: Double? = nil,
        paymentTerms: String? = nil,
        outstandingBalance: Double? = nil,
        balanceType: String? = nil,
        status: String? = nil,
        priceTier: String? = nil,
        vehicleSegmentAccess: String? = nil,
        allowedVehicleSegments: [String]? = nil,
        enableMobileApp: Bool? = nil,
        avatarUrl: String? = nil,
        avatar: String? = nil
    ) {
        self._id = _id
        self.id = id
        self.code = code
        self.name = name
        self.tallyLedgerName = tallyLedgerName
        self.group = group
        self.category = category
        self.address = address
        self.city = city
        self.state = state
        self.country = country
        self.pincode = pincode
        self.phone = phone
        self.email = email
        self.gstin = gstin
        self.bankName = bankName
        self.bankAccount = bankAccount
        self.bankIfsc = bankIfsc
        self.bankBranch = bankBranch
        self.creditLimit = creditLimit
        self.paymentTerms = paymentTerms
        self.outstandingBalance = outstandingBalance
        self.balanceType = balanceType
        self.status = status
        self.priceTier = priceTier
        self.vehicleSegmentAccess = vehicleSegmentAccess
        self.allowedVehicleSegments = allowedVehicleSegments
        self.enableMobileApp = enableMobileApp
        self.avatarUrl = avatarUrl
        self.avatar = avatar
    }

    public func withUpdatedAvatar(_ url: String) -> CustomerDetailModel {
        return CustomerDetailModel(
            _id: self._id,
            id: self.id,
            code: self.code,
            name: self.name,
            tallyLedgerName: self.tallyLedgerName,
            group: self.group,
            category: self.category,
            address: self.address,
            city: self.city,
            state: self.state,
            country: self.country,
            pincode: self.pincode,
            phone: self.phone,
            email: self.email,
            gstin: self.gstin,
            bankName: self.bankName,
            bankAccount: self.bankAccount,
            bankIfsc: self.bankIfsc,
            bankBranch: self.bankBranch,
            creditLimit: self.creditLimit,
            paymentTerms: self.paymentTerms,
            outstandingBalance: self.outstandingBalance,
            balanceType: self.balanceType,
            status: self.status,
            priceTier: self.priceTier,
            vehicleSegmentAccess: self.vehicleSegmentAccess,
            allowedVehicleSegments: self.allowedVehicleSegments,
            enableMobileApp: self.enableMobileApp,
            avatarUrl: url,
            avatar: url
        )
    }
}

public struct EditCustomerRequest: Codable {
    public let name: String?
    public let phone: String?
    public let email: String?
    public let address: String?
    public let city: String?
    public let state: String?
    public let pincode: String?
    public let gstin: String?
    public let creditLimit: Double?
    public let paymentTerms: String?
    public let priceTier: String?
    public let password: String?
}
