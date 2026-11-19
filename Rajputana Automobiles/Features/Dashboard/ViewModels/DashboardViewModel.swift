import Foundation
import SwiftUI

@Observable
public final class DashboardViewModel {
    public var data: DashboardAggregatedData? = nil
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    public init() {}

    public func loadDashboard() async {
        guard let session = SessionManager.shared.session else { return }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let result = try await DashboardService.shared.fetchDashboardBundle(
                token: session.token,
                canViewAuditLogs: session.canView(.auditLogs)
            )
            await MainActor.run {
                self.data = result
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
