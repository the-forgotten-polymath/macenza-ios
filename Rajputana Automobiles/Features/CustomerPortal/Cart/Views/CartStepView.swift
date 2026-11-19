import SwiftUI

public struct CartStepView: View {
    @Bindable var viewModel: CartViewModel
    public var onProceed: () -> Void
    public var onContinueBrowsing: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirm: Bool = false

    public init(viewModel: CartViewModel, onProceed: @escaping () -> Void, onContinueBrowsing: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onProceed = onProceed
        self.onContinueBrowsing = onContinueBrowsing
    }

    public var body: some View {
        ZStack {
            LiquidTheme.canvasBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.items.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundStyle(Color(hex: 0x94A3B8))

                        Text("Your cart is empty")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(hex: 0x0F172A))

                        Text("Explore our catalogue and add genuine auto parts to your cart.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(hex: 0x64748B))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button {
                            if let onContinueBrowsing = onContinueBrowsing {
                                onContinueBrowsing()
                            } else {
                                dismiss()
                            }
                        } label: {
                            Text("Browse Catalogue")
                                .font(AppTypography.captionBold)
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(LiquidTheme.activePillGradient)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 8)

                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            // ── HERO HEADER (Matching Android) ────────
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Purchase Cart")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Color(hex: 0x0F172A))

                                    Spacer()

                                    Text("\(viewModel.items.count) Distinct SKUs")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color(hex: 0x1E40AF))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: 0xDBEAFE))
                                        .clipShape(Capsule())
                                }

                                Text("Review your selected parts, quantities and price calculation before placing your order.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(Color(hex: 0x64748B))
                                    .lineSpacing(2)
                            }
                            .padding(16)
                            .liquidCard(cornerRadius: 16)

                            // ── SECTION HEADER ────────────────────────
                            HStack {
                                Text("CART ITEMS (\(viewModel.items.count))")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x64748B))

                                Spacer()

                                Button {
                                    showClearConfirm = true
                                } label: {
                                    Text("Clear all items")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(LiquidTheme.electricBlue)
                                }
                            }
                            .padding(.horizontal, 4)

                            // ── CART ITEMS ────────────────────────────
                            ForEach(viewModel.items) { item in
                                cartItemCard(item)
                            }

                            // ── NEED MORE PARTS? CARD (Matching Android) ──
                            HStack(spacing: 12) {
                                Image(systemName: "plus.viewfinder")
                                    .font(.system(size: 24))
                                    .foregroundStyle(LiquidTheme.electricBlue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Need more parts?")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color(hex: 0x0F172A))
                                    Text("Add more items before checkout")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(hex: 0x64748B))
                                }

                                Spacer()

                                Button {
                                    if let onContinueBrowsing = onContinueBrowsing {
                                        onContinueBrowsing()
                                    } else {
                                        dismiss()
                                    }
                                } label: {
                                    Text("Browse")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(LiquidTheme.electricBlue)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(LiquidTheme.electricBlue.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(14)
                            .liquidCard(cornerRadius: 16)

                            // ── ORDER SUMMARY CARD ────────────────────
                            summaryCard

                            Spacer().frame(height: 100)
                        }
                        .padding(16)
                    }

                    // ── BOTTOM PROCEED BAR (Liquid Glass Dock) ───
                    VStack(spacing: 0) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("TOTAL PAYABLE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x64748B))
                                Text(CurrencyFormatter.formatINR(viewModel.netTotal))
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: 0x0F172A))
                                    .monospacedDigit()
                            }

                            Spacer()

                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onProceed()
                            }) {
                                HStack(spacing: 6) {
                                    Text("Proceed to Address")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 22)
                                .frame(height: 50)
                                .background(LiquidTheme.activePillGradient)
                                .clipShape(Capsule())
                                .shadow(color: LiquidTheme.electricBlue.opacity(0.35), radius: 8, x: 0, y: 3)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 12)
                    }
                    .background(
                        Color.white.opacity(0.85)
                            .background(.ultraThinMaterial)
                    )
                    .overlay(
                        Rectangle()
                            .fill(LiquidTheme.glassBorder)
                            .frame(height: 1),
                        alignment: .top
                    )
                }
            }
        }
        .alert("Notice", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .confirmationDialog("Clear Cart?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear All Items", role: .destructive) {
                viewModel.clearCart()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove all items from your cart? This cannot be undone.")
        }
    }

    private func cartItemCard(_ item: CartApiItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteImageView(urlString: item.imageUrl, contentMode: .fit, placeholderIcon: "car.side.fill")
                .frame(width: 76, height: 76)
                .background(Color(hex: 0xF8FAFC))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LiquidTheme.glassBorder, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.partNumber)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LiquidTheme.electricBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(LiquidTheme.electricBlue.opacity(0.1))
                        .clipShape(Capsule())

                    Spacer()

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.removeItem(itemId: item.id)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: 0x94A3B8))
                            .frame(width: 28, height: 28)
                    }
                }

                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0F172A))
                    .lineLimit(2)

                Text("Dealer: \(CurrencyFormatter.formatINR(item.dealerPrice))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: 0x64748B))
                    .monospacedDigit()

                HStack {
                    Text(CurrencyFormatter.formatINR(item.lineTotal))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(LiquidTheme.electricBlue)
                        .monospacedDigit()

                    Spacer()

                    // Quantity Stepper
                    HStack(spacing: 12) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.updateQuantity(itemId: item.id, newQty: item.quantity - 1)
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: 0x0F172A))
                                .frame(width: 30, height: 30)
                                .background(Color(hex: 0xF1F5F9))
                                .clipShape(Circle())
                        }

                        Text("\(item.quantity)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: 0x0F172A))
                            .monospacedDigit()
                            .frame(minWidth: 20)

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.updateQuantity(itemId: item.id, newQty: item.quantity + 1)
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(LiquidTheme.activePillGradient)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .liquidCard(cornerRadius: 18)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Order Summary")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: 0x111827))

            VStack(spacing: 10) {
                HStack {
                    Text("Subtotal (\(viewModel.totalUnits) Units)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: 0x6B7280))
                    Spacer()
                    Text(CurrencyFormatter.formatINR(viewModel.subtotal))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: 0x111827))
                }

                HStack {
                    Text("Estimated GST (18%)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: 0x6B7280))
                    Spacer()
                    Text(CurrencyFormatter.formatINR(viewModel.gstAmount))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: 0x111827))
                }

                HStack {
                    Text("Freight & Handling")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: 0x6B7280))
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: 0x3158D4))
                        Text("Free Partner Delivery")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: 0x3158D4))
                    }
                }
            }

            Divider()
                .padding(.vertical, 2)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Net Amount")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0x111827))
                    Text("Includes all statutory duties & cess")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x6B7280))
                }

                Spacer()

                Text(CurrencyFormatter.formatINR(viewModel.netTotal))
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Color(hex: 0x111827))
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }
}
