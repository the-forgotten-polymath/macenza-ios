import Foundation

public struct CompanyProfile: Codable {
    public let _id: String?
    public var name: String
    public var tagline: String
    public var gstin: String
    public var phone: String
    public var supportEmail: String
    public var address: String

    public var email: String?
    public var bankName: String?
    public var bankAccount: String?
    public var bankIfsc: String?
    public var bankBranch: String?
    public var pan: String?

    public var tallySyncStatus: TallySyncStatus?
    public var logo: String?
    public var logoName: String?
    public var watermark: String?
    public var watermarkName: String?
    public var watermarkSettings: WatermarkSettings?

    public init(
        _id: String? = nil,
        name: String = "Rajputana Automobiles",
        tagline: String = "",
        gstin: String = "",
        phone: String = "",
        supportEmail: String = "",
        address: String = "",
        email: String? = nil,
        bankName: String? = nil,
        bankAccount: String? = nil,
        bankIfsc: String? = nil,
        bankBranch: String? = nil,
        pan: String? = nil,
        tallySyncStatus: TallySyncStatus? = nil,
        logo: String? = nil,
        logoName: String? = nil,
        watermark: String? = nil,
        watermarkName: String? = nil,
        watermarkSettings: WatermarkSettings? = nil
    ) {
        self._id = _id
        self.name = name
        self.tagline = tagline
        self.gstin = gstin
        self.phone = phone
        self.supportEmail = supportEmail
        self.address = address
        self.email = email
        self.bankName = bankName
        self.bankAccount = bankAccount
        self.bankIfsc = bankIfsc
        self.bankBranch = bankBranch
        self.pan = pan
        self.tallySyncStatus = tallySyncStatus
        self.logo = logo
        self.logoName = logoName
        self.watermark = watermark
        self.watermarkName = watermarkName
        self.watermarkSettings = watermarkSettings
    }
}

public struct TallySyncStatus: Codable {
    public let status: String?
    public let lastSyncedAt: String?
    public let pendingRecords: Int?
    public let tallyVersion: String?
}

public struct WatermarkSettings: Codable {
    public var position: String
    public var opacity: Double
    public var scale: Double

    public init(position: String = "bottom-right", opacity: Double = 0.75, scale: Double = 28.0) {
        self.position = position
        self.opacity = opacity
        self.scale = scale
    }
}

public struct BulkSaveMatrixRequest: Codable {
    public let roles: [RoleResponse]
    public let permissionsMap: [String: [String: ModulePermission]]

    public init(roles: [RoleResponse], permissionsMap: [String: [String: ModulePermission]]) {
        self.roles = roles
        self.permissionsMap = permissionsMap
    }
}
