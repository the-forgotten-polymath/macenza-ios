import SwiftUI

public struct OrderDetailView: View {
    public let orderId: String
    public var initialOrder: OrderModel? = nil
    public var canEdit: Bool = true
    public var onBack: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var order: OrderModel? = nil
    @State private var isLoading: Bool = false
    @State private var isUpdatingStatus: Bool = false
    @State private var showLrSheet: Bool = false
    @State private var showApproveConfirm: Bool = false
    @State private var showRejectConfirm: Bool = false
    @State private var showLrNotAllowedAlert: Bool = false
    @State private var errorMessage: String? = nil

    public init(
        orderId: String,
        initialOrder: OrderModel? = nil,
        canEdit: Bool = true,
        onBack: (() -> Void)? = nil
    ) {
        self.orderId = orderId
        self.initialOrder = initialOrder
        self._order = State(initialValue: initialOrder)
        self.canEdit = canEdit
        self.onBack = onBack
    }

    public var body: some View {
        ZStack {
            Color(hex: 0xF8FAFC).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top App Bar (Android 1:1) ──────────────────────
                topAppBar

                // ── Content ─────────────────────────────────────────
                if isLoading && order == nil {
                    orderLoadingSkeleton
                } else if let o = order {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            // 1. Order Header Card (Image 4)
                            orderHeaderCard(o)
                                .padding(.horizontal, 14)
                                .padding(.top, 10)

                            // 2. Customer & Shipping Details Card (Image 4)
                            customerShippingCard(o)
                                .padding(.horizontal, 14)

                            // 3. Ordered Spare Parts Section (Image 4)
                            orderedSparePartsSection(o)
                                .padding(.horizontal, 14)

                            // 4. Payment & Tax Breakdown Card (Image 4)
                            paymentBreakdownCard(o)
                                .padding(.horizontal, 14)

                            // 5. Action Buttons (Image 4)
                            if canEdit {
                                actionButtonsStack(o)
                                    .padding(.horizontal, 14)
                                    .padding(.top, 4)
                            }

                            Spacer().frame(height: 32)
                        }
                    }
                    .refreshable {
                        await reloadOrder()
                    }
                } else if let err = errorMessage {
                    errorStateView(err)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadOrder()
            if ProcessInfo.processInfo.arguments.contains("-openLrSheet") {
                showLrSheet = true
            }
        }
        .sheet(isPresented: $showLrSheet) {
            if let o = order {
                LorryReceiptSheet(order: o) { updated in
                    self.order = updated
                }
            }
        }
        .alert("Approve Order", isPresented: $showApproveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Approve", role: .none) {
                Task { await updateStatus("Approved") }
            }
        } message: {
            Text("Are you sure you want to approve \(order?.displayOrderNumber ?? "this order")?")
        }
        .alert("Reject Order", isPresented: $showRejectConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reject", role: .destructive) {
                Task { await updateStatus("Rejected") }
            }
        } message: {
            Text("Are you sure you want to reject \(order?.displayOrderNumber ?? "this order")?")
        }
        .alert("Lorry Receipt (LR)", isPresented: $showLrNotAllowedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Approve the order first to add or view the Lorry Receipt (LR)")
        }
    }

    // ── TOP APP BAR (Android 1:1) ────────────────────────────────────
    private var topAppBar: some View {
        HStack(spacing: 12) {
            Button {
                if let back = onBack {
                    back()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .frame(width: 36, height: 36)
            }

            Text("Order Details")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))

            Spacer()

            Button {
                Task { await reloadOrder() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(hex: 0xE2E8F0)),
            alignment: .bottom
        )
    }

    // ── 1. ORDER HEADER CARD (Image 4) ───────────────────────────────
    private func orderHeaderCard(_ o: OrderModel) -> some View {
        let (statusBg, statusFg) = statusColors(o.displayStatus)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(o.displayOrderNumber)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x0F172A))

                Spacer()

                // Status Pill (e.g. CONFIRMED)
                Text(o.displayStatus.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(statusFg)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusBg)
                    .clipShape(Capsule())
            }

            Rectangle()
                .fill(Color(hex: 0xE2E8F0))
                .frame(height: 1)

            HStack(alignment: .center) {
                Image(systemName: "calendar")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0x94A3B8))

                Text("Placed on \(formatDate(o.effectiveDate))")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))

                Spacer()

                Text("Ref: \(o.lrLabel)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 2. CUSTOMER & SHIPPING DETAILS CARD (Image 4) ────────────────
    private func customerShippingCard(_ o: OrderModel) -> some View {
        let ship = o.shipping

        return VStack(alignment: .leading, spacing: 14) {
            // Header Row
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(hex: 0xEFF6FF))
                        .frame(width: 26, height: 26)

                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x2563EB))
                }

                Text("Customer & Shipping Details")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Customer")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: 0x0F172A))

                // Address
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .frame(width: 16)
                        .padding(.top, 1)

                    Text(buildAddress(ship: ship))
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x334155))
                        .lineSpacing(3)
                }

                // Phone
                if let phone = ship?.phone, !phone.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "phone")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: 0x94A3B8))
                            .frame(width: 16)

                        Text(phone)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0x334155))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    private func buildAddress(ship: ShippingInfo?) -> String {
        guard let s = ship else { return "Ajmer, Kota – 324001, Kota, Rajasthan - 324001" }
        var parts: [String] = []
        if let line = s.line, !line.isEmpty { parts.append(line) }
        if let city = s.city, !city.isEmpty { parts.append(city) }
        if let state = s.state, !state.isEmpty { parts.append(state) }
        let base = parts.joined(separator: ", ")
        if let pin = s.pincode, !pin.isEmpty {
            return "\(base) - \(pin)"
        }
        return base.isEmpty ? "Ajmer, Kota – 324001, Kota, Rajasthan - 324001" : base
    }

    // ── 3. ORDERED SPARE PARTS SECTION (Image 4) ─────────────────────
    private func orderedSparePartsSection(_ o: OrderModel) -> some View {
        let items = o.items ?? []
        let totalSkus = items.reduce(0) { $0 + ($1.qty ?? 1) }

        return VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .center) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: 0x2563EB))

                Text("Ordered Spare Parts (\(o.displayItemCount))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Spacer()

                Text("Total \(totalSkus) SKUs")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))
            }
            .padding(.horizontal, 2)

            // Items List
            if items.isEmpty {
                VStack(spacing: 8) {
                    Text("No line items")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x64748B))
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        itemRowCard(item)
                    }
                }
            }
        }
    }

    private func itemRowCard(_ item: OrderItem) -> some View {
        let qty = item.qty ?? 1
        let rate = item.effectiveRate
        let lineTotal = item.lineTotal

        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .lineLimit(2)

                Text("PN: \(item.effectiveCode)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: 0x64748B))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(formatRupees(lineTotal))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Text("\(qty) × \(formatRupees(rate))")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 4. PAYMENT & TAX BREAKDOWN CARD (Image 4) ────────────────────
    private func paymentBreakdownCard(_ o: OrderModel) -> some View {
        let subtotal = o.subtotal ?? (o.effectiveAmount / 1.18)
        let gst = o.gst ?? (o.effectiveAmount - subtotal)
        let total = o.total ?? o.effectiveAmount

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "creditcard")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: 0x059669))

                Text("Payment & Tax Breakdown")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
            }

            VStack(spacing: 8) {
                breakdownRow(label: "Taxable Value (Subtotal):", value: formatRupees(subtotal))
                breakdownRow(label: "GST (18% Included):", value: formatRupees(gst))
            }

            Rectangle()
                .fill(Color(hex: 0xE2E8F0))
                .frame(height: 1)

            HStack {
                Text("Total Amount:")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Spacer()

                Text(formatRupees(total))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: 0x2563EB))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    private func breakdownRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0x64748B))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: 0x0F172A))
        }
    }

    // ── 5. ACTION BUTTONS (Image 4) ──────────────────────────────────
    private func actionButtonsStack(_ o: OrderModel) -> some View {
        let isApproved = o.displayStatus.caseInsensitiveCompare("Approved") == .orderedSame
        let isRejected = o.displayStatus.caseInsensitiveCompare("Rejected") == .orderedSame || o.displayStatus.caseInsensitiveCompare("Cancelled") == .orderedSame

        return VStack(spacing: 10) {
            // Row 1: Approve Order | Reject Order
            HStack(spacing: 10) {
                // Approve Button
                Button {
                    if !isApproved && !isUpdatingStatus {
                        showApproveConfirm = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isUpdatingStatus {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isApproved ? "Already Approved" : "Approve Order")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isApproved ? Color(hex: 0x059669) : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(isApproved ? Color(hex: 0xECFDF5) : Color(hex: 0x059669))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isApproved || isUpdatingStatus)

                // Reject Button
                Button {
                    if !isRejected && !isUpdatingStatus {
                        showRejectConfirm = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                        Text(isRejected ? "Rejected Order" : "Reject Order")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0xDC2626))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(isRejected ? Color(hex: 0xFEF2F2) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: 0xDC2626), lineWidth: 1)
                    )
                }
                .disabled(isRejected || isUpdatingStatus)
            }

            // Row 2: Lorry Receipt (LR) Button
            Button {
                if o.canManageLr {
                    showLrSheet = true
                } else {
                    showLrNotAllowedAlert = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 15))
                    Text("Lorry Receipt (LR)")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(Color(hex: 0x059669))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(hex: 0xECFDF5).opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: 0x10B981), lineWidth: 1)
                )
            }
        }
    }

    // ── HELPERS & ACTIONS ────────────────────────────────────────────
    private func loadOrder() async {
        guard let token = SessionManager.shared.session?.token else { return }
        if order == nil {
            isLoading = true
        }
        errorMessage = nil
        do {
            let fetched = try await OrderService.shared.fetchOrderById(token: token, id: orderId)
            await MainActor.run {
                self.order = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                if self.order == nil {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func reloadOrder() async {
        guard let token = SessionManager.shared.session?.token else { return }
        do {
            let fetched = try await OrderService.shared.fetchOrderById(token: token, id: orderId)
            await MainActor.run {
                self.order = fetched
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func updateStatus(_ newStatus: String) async {
        guard let token = SessionManager.shared.session?.token else { return }
        isUpdatingStatus = true
        do {
            let updated = try await OrderService.shared.updateOrderStatus(token: token, id: orderId, status: newStatus)
            await MainActor.run {
                self.order = updated
                self.isUpdatingStatus = false
            }
        } catch {
            await MainActor.run {
                self.isUpdatingStatus = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func statusColors(_ status: String) -> (Color, Color) {
        switch status.lowercased() {
        case "delivered", "synced", "approved":
            return (Color(hex: 0xECFDF5), Color(hex: 0x059669))
        case "confirmed":
            return (Color(hex: 0xECFDF5), Color(hex: 0x059669))
        case "dispatched":
            return (Color(hex: 0xEFF6FF), Color(hex: 0x2563EB))
        case "rejected", "cancelled":
            return (Color(hex: 0xFEF2F2), Color(hex: 0xDC2626))
        case "draft":
            return (Color(hex: 0xF1F5F9), Color(hex: 0x64748B))
        default:
            return (Color(hex: 0xFEF3C7), Color(hex: 0xD97706))
        }
    }

    private func formatDate(_ dateStr: String) -> String {
        if dateStr.isEmpty { return "Recent" }
        return String(dateStr.prefix(10))
    }

    private func formatRupees(_ amount: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "en_IN")
        if floor(amount) == amount {
            nf.minimumFractionDigits = 0
            nf.maximumFractionDigits = 0
        } else {
            nf.minimumFractionDigits = 2
            nf.maximumFractionDigits = 2
        }
        let s = nf.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "₹\(s)"
    }

    private var orderLoadingSkeleton: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .frame(height: 100)
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .frame(height: 120)
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .frame(height: 160)
        }
        .padding(14)
    }

    private func errorStateView(_ err: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: 0xDC2626))
            Text("Failed to load order")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))
            Text(err)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0x64748B))
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadOrder() }
            }
            .padding(.top, 6)
        }
        .padding(32)
    }
}
