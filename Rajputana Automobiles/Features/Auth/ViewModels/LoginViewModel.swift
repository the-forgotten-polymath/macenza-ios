import Foundation
import SwiftUI

@Observable
public final class LoginViewModel {
    public var selectedRoleTab: WorkspaceRole = .superadmin
    public var email: String = ""
    public var password: String = ""
    public var rememberMe: Bool = true
    public var isPasswordVisible: Bool = false

    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    public init() {
        applyDemoCredentials(for: .superadmin)
    }

    public func onSelectRole(_ role: WorkspaceRole) {
        self.selectedRoleTab = role
        applyDemoCredentials(for: role)
    }

    public func applyDemoCredentials(for role: WorkspaceRole) {
        let creds = AuthService.demoCredentials(for: role)
        self.email = creds.email
        self.password = creds.pass
        self.errorMessage = nil
    }

    public func performLogin() async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let session = try await AuthService.shared.login(email: email, password: password)
            await MainActor.run {
                SessionManager.shared.signIn(session)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
