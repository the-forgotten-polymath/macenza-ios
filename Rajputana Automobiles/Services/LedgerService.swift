import Foundation

public final class LedgerService {
    public static let shared = LedgerService()
    private let network = NetworkService.shared

    private init() {}

    public func fetchLedgerSummary(token: String) async throws -> [LedgerSummary] {
        let endpoint = APIEndpoint(path: "api/ledger/summary", method: .get)
        return try await network.request(endpoint, token: token)
    }

    public func fetchDetailedLedger(token: String, partyName: String) async throws -> LedgerResponse {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/?#&=+;")
        let encodedParty = partyName.addingPercentEncoding(withAllowedCharacters: allowed) ?? partyName
        let endpoint = APIEndpoint(path: "api/ledger/customer/\(encodedParty)", method: .get)
        return try await network.request(endpoint, token: token)
    }

    public func fetchAllInvoices(token: String) async throws -> [Invoice] {
        let endpoint = APIEndpoint(path: "api/ledger/invoices", method: .get)
        return try await network.request(endpoint, token: token)
    }

    public func fetchInvoiceDetail(token: String, invoiceNumber: String, party: String? = nil) async throws -> Invoice {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "?#&=+;")
        let encodedNumber = invoiceNumber.addingPercentEncoding(withAllowedCharacters: allowed) ?? invoiceNumber

        var queryItems: [URLQueryItem] = []
        if let party = party, !party.isEmpty {
            queryItems.append(URLQueryItem(name: "party", value: party))
        }

        let endpoint = APIEndpoint(path: "api/ledger/invoices/\(encodedNumber)", method: .get, queryItems: queryItems)
        do {
            return try await network.request(endpoint, token: token)
        } catch {
            // Also attempt unwrapping if backend wrapped in {"invoice": ...} or {"data": ...}
            do {
                let dict: [String: AnyCodable] = try await network.request(endpoint, token: token)
                if let invObj = dict["invoice"]?.value as? [String: Any],
                   let data = try? JSONSerialization.data(withJSONObject: invObj) {
                    return try JSONDecoder().decode(Invoice.self, from: data)
                }
                if let dataObj = dict["data"]?.value as? [String: Any],
                   let data = try? JSONSerialization.data(withJSONObject: dataObj) {
                    return try JSONDecoder().decode(Invoice.self, from: data)
                }
            } catch {}
            throw error
        }
    }
}
