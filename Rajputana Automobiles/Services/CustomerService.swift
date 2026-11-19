import Foundation

public final class CustomerService {
    public static let shared = CustomerService()
    private let network = NetworkService.shared

    private init() {}

    public func fetchCustomers(token: String) async throws -> [Customer] {
        let endpoint = APIEndpoint(path: "api/customers", method: .get)
        return try await network.request(endpoint, token: token)
    }

    public func fetchCustomerDetail(token: String, id: String) async throws -> CustomerDetailModel {
        do {
            let endpoint = APIEndpoint(path: "api/customers/\(id)", method: .get)
            return try await network.request(endpoint, token: token)
        } catch {
            // If fetching directly by id fails (e.g. id is a customer code '13-raj-001' or name instead of ObjectId),
            // search the customer list to find the matching customer
            if let customers = try? await fetchCustomers(token: token) {
                if let match = customers.first(where: { c in
                    c.code.caseInsensitiveCompare(id) == .orderedSame ||
                    c.id == id ||
                    c._id == id ||
                    c.customerId == id ||
                    c.name.caseInsensitiveCompare(id) == .orderedSame
                }) {
                    let realId = match._id ?? match.customerId ?? match.id
                    if realId != id {
                        let fallbackEndpoint = APIEndpoint(path: "api/customers/\(realId)", method: .get)
                        if let direct = try? await network.request(fallbackEndpoint, token: token) as CustomerDetailModel {
                            return direct
                        }
                    }
                    return CustomerDetailModel(
                        _id: match._id,
                        id: match.customerId ?? match.id,
                        code: match.code,
                        name: match.name,
                        tallyLedgerName: match.tallyLedgerName,
                        group: match.group,
                        address: match.address,
                        city: match.city,
                        state: match.state,
                        country: match.country,
                        pincode: match.pincode,
                        phone: match.phone,
                        email: match.email,
                        gstin: match.gstin,
                        creditLimit: match.creditLimit,
                        paymentTerms: match.paymentTerms,
                        outstandingBalance: match.outstandingBalance,
                        balanceType: match.balanceType,
                        status: match.status,
                        avatarUrl: match.avatarUrl
                    )
                }
            }
            throw error
        }
    }

    public func updateCustomer(token: String, id: String, request: EditCustomerRequest) async throws -> CustomerDetailModel {
        let data = try JSONEncoder().encode(request)
        let endpoint = APIEndpoint(path: "api/customers/\(id)", method: .put, body: data)
        return try await network.request(endpoint, token: token)
    }

    public func deleteCustomer(token: String, id: String) async throws {
        let endpoint = APIEndpoint(path: "api/customers/\(id)", method: .delete)
        let _: [String: AnyCodable] = try await network.request(endpoint, token: token)
    }

    public func fetchCustomerInvoices(token: String, customerCode: String? = nil, customerName: String? = nil, tallyLedgerName: String? = nil) async throws -> [Invoice] {
        let endpoint = APIEndpoint(path: "api/ledger/invoices", method: .get)
        let allInvoices: [Invoice] = try await network.request(endpoint, token: token)

        let targetNames = [customerName, tallyLedgerName].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }

        return allInvoices.filter { inv in
            if let code = customerCode, !code.isEmpty {
                if let c = inv.customerCode, c.caseInsensitiveCompare(code) == .orderedSame { return true }
            }
            if targetNames.isEmpty { return true }

            let invParty = (inv.party ?? inv.customerName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let invName = (inv.customerName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            for target in targetNames {
                if invParty == target || invName == target || invParty.contains(target) || target.contains(invParty) {
                    return true
                }
            }
            return false
        }
    }

    public func fetchInvoiceDetail(token: String, invoiceNumber: String, party: String?) async throws -> Invoice {
        let encNum = invoiceNumber.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? invoiceNumber
        var path = "api/ledger/invoices/\(encNum)"
        if let p = party, !p.isEmpty {
            let encP = p.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? p
            path += "?party=\(encP)"
        }
        let endpoint = APIEndpoint(path: path, method: .get)
        return try await network.request(endpoint, token: token)
    }

    public func updatePortalAccess(token: String, id: String, status: String) async throws -> CustomerDetailModel {
        let body = try JSONSerialization.data(withJSONObject: ["status": status])
        let endpoint = APIEndpoint(path: "api/customers/\(id)", method: .put, body: body)
        return try await network.request(endpoint, token: token)
    }

    public func uploadAvatar(token: String, id: String, imageBase64DataUri: String, email: String? = nil, code: String? = nil) async throws -> String {
        var body: [String: String] = ["image": imageBase64DataUri]
        if let email = email, !email.isEmpty { body["email"] = email }
        if let code = code, !code.isEmpty { body["code"] = code }
        let data = try JSONSerialization.data(withJSONObject: body)
        let endpoint = APIEndpoint(path: "api/customers/\(id)/upload-avatar", method: .post, body: data)
        let response: [String: AnyCodable] = try await network.request(endpoint, token: token)
        return (response["avatarUrl"]?.value as? String) ?? (response["url"]?.value as? String) ?? ""
    }
}
