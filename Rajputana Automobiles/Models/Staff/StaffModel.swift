import Foundation

public struct StaffModel: Codable, Identifiable {
    public var id: String { _id ?? staffId ?? employeeId ?? UUID().uuidString }

    public let _id: String?
    public let staffId: String?
    public let employeeId: String?
    public let firstName: String?
    public let lastName: String?
    public let name: String?
    public let email: String
    public let phone: String?
    public let mobile: String?
    public let altMobile: String?
    public let role: String?
    public let designation: String?
    public let department: String?
    public let status: String?
    public let officeAddress: String?
    public let addressLine1: String?
    public let addressLine2: String?
    public let city: String?
    public let state: String?
    public let pincode: String?
    public let country: String?
    public let avatarUrl: String?
    public let isMasterSuperadmin: Bool?

    enum CodingKeys: String, CodingKey {
        case _id
        case staffId = "id"
        case employeeId, firstName, lastName, name, email, phone, mobile, altMobile, role, designation, department, status
        case officeAddress, addressLine1, addressLine2, city, state, pincode, country, avatarUrl, isMasterSuperadmin
    }

    public var displayName: String {
        let combined = "\((firstName ?? "").trimmingCharacters(in: .whitespaces)) \((lastName ?? "").trimmingCharacters(in: .whitespaces))".trimmingCharacters(in: .whitespaces)
        if !combined.isEmpty { return combined }
        return (name?.isEmpty == false ? name! : "Unnamed Staff")
    }

    public var effectiveEmployeeId: String {
        if let emp = employeeId, !emp.isEmpty { return emp }
        if let s = staffId, !s.isEmpty { return s }
        if let m = _id, !m.isEmpty { return m }
        return "EMP-103"
    }

    public var effectivePhone: String {
        let p = mobile ?? phone ?? ""
        if !p.isEmpty { return p.hasPrefix("+") ? p : "+91 \(p)" }
        return "Phone not available"
    }

    public var effectiveLocation: String {
        let parts = [city, state].compactMap { $0 }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return parts.isEmpty ? "Jaipur, Rajasthan" : parts.joined(separator: ", ")
    }

    public var isMaster: Bool {
        return (isMasterSuperadmin == true) || (role?.lowercased() == "superadmin")
    }

    public var displayRole: String {
        return role?.capitalized ?? "Staff"
    }

    public var isActive: Bool {
        return status?.lowercased() != "inactive"
    }
}

public struct StaffRequest: Codable {
    public let employeeId: String?
    public let name: String
    public let email: String
    public let phone: String?
    public let role: String
    public let designation: String?
    public let department: String?
    public let status: String?
    public let officeAddress: String?
    public let city: String?
    public let state: String?
    public let pincode: String?

    public init(
        employeeId: String? = nil,
        name: String,
        email: String,
        phone: String? = nil,
        role: String = "admin",
        designation: String? = nil,
        department: String? = nil,
        status: String? = "Active",
        officeAddress: String? = nil,
        city: String? = nil,
        state: String? = nil,
        pincode: String? = nil
    ) {
        self.employeeId = employeeId
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.designation = designation
        self.department = department
        self.status = status
        self.officeAddress = officeAddress
        self.city = city
        self.state = state
        self.pincode = pincode
    }
}
