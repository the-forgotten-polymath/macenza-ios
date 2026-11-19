import SwiftUI

public struct LoginView: View {
    @State private var viewModel = LoginViewModel()

    public init() {}

    public var body: some View {
        ZStack {
            LiquidTheme.canvasBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    // ── LOGO & HEADER ──────────────────────────────
                    VStack(spacing: 12) {
                        Image("app_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: LiquidTheme.electricBlue.opacity(0.2), radius: 10, x: 0, y: 5)

                        Text("Rajputana Automobiles")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(LiquidTheme.textPrimary)

                        Text("Auto Parts Distribution ERP Portal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: 0x64748B))
                    }

                    // ── ROLE SELECTOR TABS ─────────────────────────
                    HStack(spacing: 6) {
                        roleTabButton(title: "Super Admin", role: .superadmin)
                        roleTabButton(title: "Admin", role: .admin)
                        roleTabButton(title: "Customer", role: .customer)
                    }
                    .padding(5)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(LiquidTheme.glassBorder, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                    // ── LOGIN FORM CARD ────────────────────────────
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Sign In to Your Account")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(LiquidTheme.textPrimary)

                        if let error = viewModel.errorMessage {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color(hex: 0xDC2626))
                                Text(error)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: 0xDC2626))
                            }
                            .padding(10)
                            .background(LiquidTheme.trendRedBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        // Email Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x475569))

                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundStyle(Color(hex: 0x94A3B8))
                                    .frame(width: 20)
                                TextField("Enter email", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(12)
                            .background(Color(hex: 0xF8FAFC))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(LiquidTheme.glassBorder, lineWidth: 1))
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x475569))

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundStyle(Color(hex: 0x94A3B8))
                                    .frame(width: 20)

                                if viewModel.isPasswordVisible {
                                    TextField("Enter password", text: $viewModel.password)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .font(.system(size: 14, weight: .medium))
                                } else {
                                    SecureField("Enter password", text: $viewModel.password)
                                        .font(.system(size: 14, weight: .medium))
                                }

                                Button(action: { viewModel.isPasswordVisible.toggle() }) {
                                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundStyle(Color(hex: 0x94A3B8))
                                }
                            }
                            .padding(12)
                            .background(Color(hex: 0xF8FAFC))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(LiquidTheme.glassBorder, lineWidth: 1))
                        }

                        // Remember Me
                        Toggle(isOn: $viewModel.rememberMe) {
                            Text("Keep me signed in")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color(hex: 0x475569))
                        }
                        .toggleStyle(SwitchToggleStyle(tint: LiquidTheme.electricBlue))

                        // Submit Button
                        Button(action: {
                            Task {
                                await viewModel.performLogin()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(LiquidTheme.activePillGradient)
                            .clipShape(Capsule())
                            .shadow(color: LiquidTheme.electricBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(20)
                    .liquidCard(cornerRadius: 22)

                    // ── DEMO NOTICE ────────────────────────────────
                    Text("Selecting a role tab above pre-fills demonstration credentials.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: 0x94A3B8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .task {
            if ProcessInfo.processInfo.arguments.contains("-autoLoginAdminStaff") {
                viewModel.onSelectRole(.admin)
                await viewModel.performLogin()
            } else if ProcessInfo.processInfo.arguments.contains("-autoLoginAdmin") {
                viewModel.onSelectRole(.superadmin)
                await viewModel.performLogin()
            } else if ProcessInfo.processInfo.arguments.contains("-autoLoginCustomer") {
                viewModel.onSelectRole(.customer)
                await viewModel.performLogin()
            }
        }
    }

    private func roleTabButton(title: String, role: WorkspaceRole) -> some View {
        let isSelected = viewModel.selectedRoleTab == role
        return Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                viewModel.onSelectRole(role)
            }
        }) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : Color(hex: 0x475569))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? LiquidTheme.activePillGradient : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                .clipShape(Capsule())
                .shadow(color: isSelected ? LiquidTheme.electricBlue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
    }
}
