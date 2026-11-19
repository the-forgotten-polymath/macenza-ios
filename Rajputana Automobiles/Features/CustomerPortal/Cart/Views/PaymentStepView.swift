import SwiftUI

public struct PaymentStepView: View {
    @Bindable var viewModel: CartViewModel
    public var onOrderPlaced: () -> Void

    @State private var utrNumber: String = ""
    @State private var copiedUpi: Bool = false
    @State private var toastMessage: String? = nil

    public init(viewModel: CartViewModel, onOrderPlaced: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onOrderPlaced = onOrderPlaced
    }

    private let upiId = "rajputana.auto@icici"

    private var upiDeepLink: URL? {
        let amount = String(format: "%.2f", viewModel.netTotal)
        let linkStr = "upi://pay?pa=\(upiId)&pn=Rajputana%20Automobiles&am=\(amount)&cu=INR"
        return URL(string: linkStr)
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.red)
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.redDeep)
                            Spacer()
                        }
                        .padding(10)
                        .background(AppColors.redLightAlt)
                        .cornerRadius(8)
                    }

                    // ── DELIVERING TO RECAP CARD ───────────────
                    if let shipping = viewModel.selectedAddress {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: 0xEFF6FF))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 18))
                                    .foregroundStyle(LiquidTheme.electricBlue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Delivering to \(shipping.label)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color(hex: 0x64748B))

                                Text(shipping.recipientName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x0F172A))
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text("\(shipping.city), \(shipping.state)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(LiquidTheme.electricBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(LiquidTheme.electricBlue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(14)
                        .liquidCard(cornerRadius: 16)
                    }

                    // ── TOTAL PAYABLE AMOUNT CARD ──────────────
                    VStack(spacing: 6) {
                        Text("TOTAL PAYABLE AMOUNT")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: 0x64748B))

                        Text(CurrencyFormatter.formatINR(viewModel.netTotal))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(LiquidTheme.electricBlue)
                            .monospacedDigit()

                        Text("Includes 18% GST (\(CurrencyFormatter.formatINR(viewModel.gstAmount))) + Complimentary Freight")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: 0x64748B))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .liquidCard(cornerRadius: 18)

                    // ── UPI / QR CODE CARD ─────────────────────
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 20))
                                .foregroundStyle(LiquidTheme.electricBlue)

                            Text("Pay via UPI / QR Code")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(hex: 0x0F172A))

                            Spacer()

                            HStack(spacing: 4) {
                                Circle().fill(Color(hex: 0x10B981)).frame(width: 6, height: 6)
                                Text("Instant Settlement")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x059669))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: 0xECFDF5))
                            .clipShape(Capsule())
                        }

                        // Simulated Visual QR Container matching Android
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1.5)
                                    .background(Color.white)
                                    .frame(width: 170, height: 170)

                                VStack(spacing: 8) {
                                    Image(systemName: "qrcode")
                                        .font(.system(size: 110))
                                        .foregroundStyle(Color(hex: 0x0F172A))

                                    Text("RA-B2B-UPI")
                                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                        .foregroundStyle(LiquidTheme.electricBlue)
                                }
                            }

                            Text("Scan with any UPI app to pay \(CurrencyFormatter.formatINR(viewModel.netTotal))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(hex: 0x0F172A))

                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showToast("QR details saved to photo gallery preview")
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save QR Code")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x475569))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color(hex: 0xF1F5F9))
                                .clipShape(Capsule())
                            }
                        }

                        Divider()

                        // UPI APPS GRID
                        VStack(spacing: 10) {
                            Text("OR PAY USING UPI APPS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: 0x9CA3AF))

                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                upiAppButton(name: "Google Pay", schemes: ["tez", "gpay"])
                                upiAppButton(name: "PhonePe", schemes: ["phonepe"])
                                upiAppButton(name: "Paytm", schemes: ["paytmmp", "paytm"])
                                upiAppButton(name: "BHIM UPI", schemes: ["bhim"])
                            }
                        }

                        Divider()

                        // DIRECT VPA / UPI ID ROW
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PAY DIRECTLY TO VERIFIED BUSINESS VPA / UPI ID")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: 0x64748B))

                            HStack {
                                Text(upiId)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(hex: 0x0F172A))

                                Spacer()

                                Button {
                                    UIPasteboard.general.string = upiId
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    withAnimation { copiedUpi = true }
                                    showToast("UPI ID copied to clipboard!")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { copiedUpi = false }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: copiedUpi ? "checkmark" : "doc.on.doc")
                                        Text(copiedUpi ? "Copied" : "Copy")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(copiedUpi ? Color(hex: 0x059669) : LiquidTheme.electricBlue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(copiedUpi ? Color(hex: 0xECFDF5) : LiquidTheme.electricBlue.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(12)
                            .background(Color(hex: 0xF8FAFC))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
                        }

                        // UTR / REFERENCE NUMBER INPUT FIELD (Exact match to Android)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("BANK UTR / REFERENCE NUMBER (OPTIONAL)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: 0x64748B))

                            TextField("e.g. 423981029384", text: $utrNumber)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
                                .keyboardType(.numberPad)

                            Text("Enter 12-digit UTR / Ref No. after payment (optional for automatic match)")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: 0x64748B))
                        }

                        // SECURE BADGE
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: 0x059669))
                            Text("100% Secure & Encrypted Direct UPI Settlement")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: 0x059669))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color(hex: 0xECFDF5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(18)
                    .liquidCard(cornerRadius: 18)

                    Spacer().frame(height: 80)
                }
                .padding(16)
            }

            // Bottom place order
            VStack(spacing: 8) {
                Divider()
                Button(action: {
                    Task {
                        let success = await viewModel.placeOrder()
                        if success {
                            onOrderPlaced()
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isPlacingOrder {
                            ProgressView().tint(.white)
                            Text("Transmitting to ERP...")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Confirm & Place Order")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: 0x059669))
                    .cornerRadius(10)
                    .shadow(color: Color(hex: 0x059669).opacity(0.3), radius: 6, x: 0, y: 2)
                }
                .disabled(viewModel.isPlacingOrder)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(AppColors.cardBackground)
        }
        .overlay(alignment: .bottom) {
            if let msg = toastMessage {
                Text(msg)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func upiAppButton(name: String, schemes: [String]) -> some View {
        Button {
            openUpiApp(name: name, schemes: schemes)
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: 0xF3F4F6))
                    .frame(width: 20, height: 20)

                Text(name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0x111827))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: 0xD1D5DB))
            }
            .padding(10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: 0xE5EAF3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func openUpiApp(name: String, schemes: [String]) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let amountStr = String(format: "%.2f", viewModel.netTotal)
        let payeeName = "Rajputana Automobiles".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Rajputana%20Automobiles"
        let note = "Order Payment RA".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Order%20Payment%20RA"
        let tr = "RA\(Int(Date().timeIntervalSince1970))"

        let query = "pa=\(upiId)&pn=\(payeeName)&am=\(amountStr)&cu=INR&tn=\(note)&tr=\(tr)"

        // 1. Try app-specific URL schemes with pre-filled payment details
        for scheme in schemes {
            if let appUrl = URL(string: "\(scheme)://upi/pay?\(query)"), UIApplication.shared.canOpenURL(appUrl) {
                UIApplication.shared.open(appUrl, options: [:])
                showToast("Opening \(name) with ₹\(amountStr) pre-filled...")
                return
            }
        }

        // 2. Try generic upi://pay scheme with pre-filled payment details
        if let genericUrl = URL(string: "upi://pay?\(query)"), UIApplication.shared.canOpenURL(genericUrl) {
            UIApplication.shared.open(genericUrl, options: [:])
            showToast("Opening UPI app with ₹\(amountStr) pre-filled...")
            return
        }

        // 3. Fallback when running on Simulator or app is not installed
        UIPasteboard.general.string = "\(upiId)"
        showToast("Copied \(upiId) (₹\(amountStr)) for \(name)")
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }

    private func paymentRow(label: String, val: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)
            Spacer()
            Text(val)
                .font(AppTypography.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textDark)
        }
    }
}
