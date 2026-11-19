import SwiftUI

/// Customer-role ledger route matching Android's `CustomerLedgerRoute.kt`.
///
/// Automatically resolves the authenticated customer's Tally Ledger Name
/// (`tallyLedgerName`) from the customer profile so that the backend authorization
/// permits reading the customer's own statement, and renders `DetailedLedgerView`
/// with `showTopBar = false` to eliminate dual header and toolbar clipping.
public struct CustomerLedgerRouteView: View {
    @State private var isLoading: Bool = true
    @State private var resolvedLedgerName: String? = nil
    @State private var errorMessage: String? = nil

    public init() {}

    public var body: some View {
        ZStack {
            LiquidTheme.canvasBackground.ignoresSafeArea()

            if let name = resolvedLedgerName, !name.isEmpty {
                DetailedLedgerView(
                    customerName: name,
                    showTopBar: false
                )
            } else if isLoading {
                customerLedgerSkeleton
            } else if let err = errorMessage {
                errorView(message: err)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await resolveAndLoadLedger()
        }
    }

    // ── Skeleton Loader matching Android's CustomerLedgerRouteSkeleton ─
    private var customerLedgerSkeleton: some View {
        VStack(spacing: 14) {
            ShimmerBox(height: 74, cornerRadius: 16)

            HStack(spacing: 10) {
                ShimmerBox(height: 76, cornerRadius: 14)
                ShimmerBox(height: 76, cornerRadius: 14)
            }

            HStack(spacing: 10) {
                ShimmerBox(height: 76, cornerRadius: 14)
                ShimmerBox(height: 76, cornerRadius: 14)
            }

            ShimmerBox(height: 48, cornerRadius: 12)

            ForEach(0..<4, id: \.self) { _ in
                ShimmerBox(height: 70, cornerRadius: 14)
            }

            Spacer()
        }
        .padding(16)
    }

    // ── Error View with Retry ────────────────────────────────────
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(Color(hex: 0xDC2626))

            Text("Couldn't load your account")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(LiquidTheme.textPrimary)

            Text(message)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(hex: 0x64748B))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: {
                Task { await resolveAndLoadLedger(forceRefresh: true) }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(LiquidTheme.activePillGradient)
                .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(24)
    }

    // ── Customer Ledger Name Resolution ─────────────────────────
    private func resolveAndLoadLedger(forceRefresh: Bool = false) async {
        guard let session = SessionManager.shared.session else {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "No active session found. Please sign in again."
            }
            return
        }

        // Fast-path: Check session's tallyLedgerName or cached profile first
        if !forceRefresh {
            if let sessionLedger = session.tallyLedgerName, !sessionLedger.isEmpty {
                await MainActor.run {
                    self.resolvedLedgerName = sessionLedger
                    self.isLoading = false
                    self.errorMessage = nil
                }
                return
            }

            if let cached = SessionManager.shared.cachedCustomerDetail {
                let name = cached.tallyLedgerName?.trimmingCharacters(in: .whitespaces)
                let resolved = (name?.isEmpty == false ? name : cached.name) ?? session.name
                if !resolved.isEmpty {
                    await MainActor.run {
                        self.resolvedLedgerName = resolved
                        self.isLoading = false
                        self.errorMessage = nil
                    }
                    return
                }
            }
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        let candidates = [session.customerCode, session.userId]
            .compactMap { $0 }
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        for candidate in candidates {
            do {
                let detail = try await CustomerService.shared.fetchCustomerDetail(token: session.token, id: candidate)
                await MainActor.run {
                    SessionManager.shared.cachedCustomerDetail = detail
                    let tally = detail.tallyLedgerName?.trimmingCharacters(in: .whitespaces)
                    let resolved = (tally?.isEmpty == false ? tally : detail.name) ?? session.name
                    self.resolvedLedgerName = resolved
                    self.isLoading = false
                    self.errorMessage = nil
                }
                return
            } catch {
                #if DEBUG
                print("Failed to fetch customer profile with id '\(candidate)': \(error)")
                #endif
            }
        }

        // Fallback: If network lookup fails, check session name
        let fallback = session.tallyLedgerName ?? session.name
        if !fallback.trimmingCharacters(in: .whitespaces).isEmpty {
            await MainActor.run {
                self.resolvedLedgerName = fallback
                self.isLoading = false
                self.errorMessage = nil
            }
        } else {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Could not find a valid dealer ledger account for your profile."
            }
        }
    }
}
