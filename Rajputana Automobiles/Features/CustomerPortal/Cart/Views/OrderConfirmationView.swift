import SwiftUI

public struct OrderConfirmationView: View {
    @Bindable var viewModel: CartViewModel
    public var onFinish: () -> Void
    public var onViewOrders: () -> Void

    @State private var countdown: Int = 10
    @State private var timer: Timer? = nil
    @State private var isPulsing: Bool = false

    public init(viewModel: CartViewModel, onFinish: @escaping () -> Void, onViewOrders: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onFinish = onFinish
        self.onViewOrders = onViewOrders
    }

    public var body: some View {
        ZStack {
            LiquidTheme.canvasBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // ── SUCCESS BADGE (Animated Peak-End Moment) ──
                ZStack {
                    Circle()
                        .fill(LiquidTheme.trendGreenBg)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isPulsing ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color(hex: 0x059669))
                        .shadow(color: Color(hex: 0x059669).opacity(0.3), radius: 10, x: 0, y: 4)
                }

                VStack(spacing: 8) {
                    Text("Order Placed Successfully!")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(LiquidTheme.textPrimary)

                    Text("Your purchase has been synchronized with Tally ERP and is awaiting warehouse dispatch.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(hex: 0x64748B))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                // ── ORDER DETAILS CARD ─────────────────────────
                VStack(spacing: 14) {
                    HStack {
                        Text("Order Number")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: 0x64748B))
                        Spacer()
                        Text(viewModel.confirmedOrderNumber)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(LiquidTheme.electricBlue)
                    }

                    Divider()
                        .foregroundStyle(Color(hex: 0xF1F5F9))

                    HStack {
                        Text("Total Amount")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: 0x64748B))
                        Spacer()
                        Text(CurrencyFormatter.formatINR(viewModel.confirmedOrderTotal))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(LiquidTheme.textPrimary)
                    }

                    if let addr = viewModel.selectedAddress {
                        Divider()
                            .foregroundStyle(Color(hex: 0xF1F5F9))
                        HStack {
                            Text("Delivery City")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color(hex: 0x64748B))
                            Spacer()
                            Text("\(addr.city), \(addr.state)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(LiquidTheme.textPrimary)
                        }
                    }
                }
                .padding(18)
                .liquidCard(cornerRadius: 20)
                .padding(.horizontal, 20)

                // ── COUNTDOWN REDIRECT ─────────────────────────
                Text("Returning to catalogue in \(countdown) seconds...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: 0x94A3B8))

                Spacer()

                // ── ACTION BUTTONS ─────────────────────────────
                VStack(spacing: 12) {
                    Button(action: {
                        timer?.invalidate()
                        onFinish()
                    }) {
                        Text("Continue Browsing Catalogue")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(LiquidTheme.activePillGradient)
                            .clipShape(Capsule())
                            .shadow(color: LiquidTheme.electricBlue.opacity(0.35), radius: 10, x: 0, y: 5)
                    }

                    Button(action: {
                        timer?.invalidate()
                        onViewOrders()
                    }) {
                        Text("View My Orders")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(LiquidTheme.electricBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(LiquidTheme.softBlueBg)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            isPulsing = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer?.invalidate()
                onFinish()
            }
        }
    }
}
