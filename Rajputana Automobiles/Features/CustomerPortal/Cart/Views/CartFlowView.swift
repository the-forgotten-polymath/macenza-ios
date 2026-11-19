import SwiftUI

public struct CartFlowView: View {
    @State private var viewModel = CartViewModel.shared
    @Environment(\.dismiss) private var dismiss
    public var onBackToCatalog: (() -> Void)? = nil
    public var onNavigateToOrders: (() -> Void)? = nil

    public init(onBackToCatalog: (() -> Void)? = nil, onNavigateToOrders: (() -> Void)? = nil) {
        self.onBackToCatalog = onBackToCatalog
        self.onNavigateToOrders = onNavigateToOrders
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── STEPPER HEADER matching Android CartStepper ──────
                if viewModel.currentStep != .confirmed {
                    cartStepper
                        .padding(.vertical, 10)
                        .background(Color(hex: 0xF8FAFC))
                }

                // ── STEP CONTENT ─────────────────────────────────────
                switch viewModel.currentStep {
                case .cart:
                    CartStepView(
                        viewModel: viewModel,
                        onProceed: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.currentStep = .address
                            }
                        },
                        onContinueBrowsing: {
                            dismiss()
                            onBackToCatalog?()
                        }
                    )
                case .address:
                    AddressStepView(viewModel: viewModel) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.currentStep = .payment
                        }
                    }
                case .payment:
                    PaymentStepView(viewModel: viewModel) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.currentStep = .confirmed
                        }
                    }
                case .confirmed:
                    OrderConfirmationView(
                        viewModel: viewModel,
                        onFinish: {
                            viewModel.currentStep = .cart
                            dismiss()
                            onBackToCatalog?()
                        },
                        onViewOrders: {
                            viewModel.currentStep = .cart
                            dismiss()
                            onNavigateToOrders?()
                        }
                    )
                }
            }
            .background(Color(hex: 0xF8FAFC).ignoresSafeArea())
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("-openAddressStep") {
                    viewModel.currentStep = .address
                } else if ProcessInfo.processInfo.arguments.contains("-openPaymentStep") {
                    viewModel.currentStep = .payment
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if viewModel.currentStep == .payment {
                            withAnimation { viewModel.currentStep = .address }
                        } else if viewModel.currentStep == .address {
                            withAnimation { viewModel.currentStep = .cart }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "arrow.backward")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: 0x0F172A))
                    }
                }
            }
        }
        .task {
            await viewModel.loadCart()
        }
    }

    // ── Cart Stepper matching Android CartStepper.kt 1:1 ─────────
    private var cartStepper: some View {
        HStack(spacing: 0) {
            // White pill container
            HStack(spacing: 0) {
                // Step 1: Cart
                stepItem(step: .cart, label: "Cart")

                // Separator 1
                separatorLine

                // Step 2: Address
                stepItem(step: .address, label: "Address")

                // Separator 2
                separatorLine

                // Step 3: Payment
                stepItem(step: .payment, label: "Payment")
            }
            .padding(4)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func stepItem(step: CheckoutStep, label: String) -> some View {
        let isSelected = viewModel.currentStep == step

        return Group {
            if isSelected {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: 0x2563EB))
                        .frame(width: 6, height: 6)

                    Text(label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color(hex: 0x1B2537))
                .clipShape(Capsule())
            } else {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: 0x64748B))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
            }
        }
    }

    private var separatorLine: some View {
        Rectangle()
            .fill(Color(hex: 0xE2E8F0))
            .frame(width: 14, height: 1)
    }
}
