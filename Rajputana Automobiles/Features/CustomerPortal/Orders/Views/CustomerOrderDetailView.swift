import SwiftUI

public struct CustomerOrderDetailView: View {
    public let order: OrderModel

    @Environment(\.dismiss) private var dismiss
    @State private var isReordering: Bool = false
    @State private var showCartSheet: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var reorderedSuccess: Bool = false
    @State private var invoicePdfUrl: URL? = nil
    @State private var lrDocPreviewUrl: URL? = nil

    public init(order: OrderModel) {
        self.order = order
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 1. Top Summary Card matching Android SummaryCard
                summaryCard

                // 2. Purchased Items Card matching Android LineItemsCard
                purchasedItemsCard

                // 3. Delivery Destination Card matching Android DeliveryCard
                deliveryCard

                // 4. Payment Summary Card matching Android PaymentCard
                paymentSummaryCard

                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color(hex: 0xF5F7FB).ignoresSafeArea())
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: 0x0F172A))
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            if reorderedSuccess {
                Button("Go to Cart") {
                    showCartSheet = true
                }
                Button("Keep Browsing", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showCartSheet) {
            CartFlowView()
        }
        .sheet(item: $invoicePdfUrl) { url in
            PDFPreviewSheet(url: url, title: "Tax Invoice \(order.displayOrderNumber)")
        }
        .sheet(item: $lrDocPreviewUrl) { url in
            PDFPreviewSheet(url: url, title: "Lorry Receipt (LR)")
        }
    }

    // ── 1. Top Summary Card ──────────────────────────────────────
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(order.displayOrderNumber)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Spacer()

                // Status Badge Pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: 0x2563EB))
                        .frame(width: 7, height: 7)

                    Text("\(order.displayStatus) & Paid")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: 0x2563EB))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: 0xEFF6FF))
                .clipShape(Capsule())
            }

            let skuCount = order.items?.count ?? 1
            Text("Placed on \(order.effectiveDate) • \(skuCount) distinct SKU\(skuCount != 1 ? "s" : "")")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0x64748B))

            // Reorder Button
            Button {
                handleReorder()
            } label: {
                HStack(spacing: 6) {
                    if isReordering {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14, weight: .bold))
                        Text("Reorder")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(hex: 0x2563EB))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isReordering || (order.items?.isEmpty ?? true))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 2. Purchased Items Card ──────────────────────────────────
    private var purchasedItemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("Purchased Items")
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Text("\(order.items?.count ?? 1)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(Circle())
            }

            if let items = order.items, !items.isEmpty {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            // Thumbnail
                            ZStack {
                                Color(hex: 0xF1F5F9)
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: 0x2563EB))
                            }
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(item.itemCode ?? "26021668")
                                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Color(hex: 0x2563EB))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: 0xEFF6FF))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))

                                    Spacer()

                                    Text(CurrencyFormatter.formatINR(item.lineTotal))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(hex: 0x0F172A))
                                }

                                Text(item.displayName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(hex: 0x0F172A))
                                    .lineLimit(1)

                                Text("Automotive Spares")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: 0x64748B))

                                HStack {
                                    Text("Qty: \(item.effectiveQuantity)")
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundColor(Color(hex: 0x475569))

                                    Spacer()

                                    Text("Unit Rate: \(CurrencyFormatter.formatINR(item.effectiveRate))")
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundColor(Color(hex: 0x475569))
                                }
                                .padding(.top, 2)
                            }
                        }

                        if item.id != items.last?.id {
                            Divider()
                                .padding(.vertical, 4)
                        }
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Color(hex: 0xF1F5F9)
                        Image(systemName: "photo.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: 0x2563EB))
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("26021668")
                                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: 0x2563EB))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: 0xEFF6FF))
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            Spacer()

                            Text(CurrencyFormatter.formatINR(order.effectiveAmount))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: 0x0F172A))
                        }

                        Text("Alternator L/L HINO 24VL")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))

                        Text("Automotive Spares")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: 0x64748B))

                        HStack {
                            Text("Qty: 3")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color(hex: 0x475569))

                            Spacer()

                            Text("Unit Rate: ₹855.00")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color(hex: 0x475569))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 3. Delivery Destination Card ─────────────────────────────
    private var deliveryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: 0x2563EB))

                Text("DELIVERY DESTINATION")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(Color(hex: 0x475569))
                    .tracking(0.5)
            }

            Text(order.shipping?.name?.isEmpty == false ? order.shipping!.name! : "M/s Bharat Bearing & Engineering Works")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))

            Text("Shop 12-14, Auto Market, Chinchwad")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0x64748B))

            Text("Pune, Maharashtra, 411019")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0x64748B))

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x475569))

                    Text("+91 97654 32100")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: 0x0F172A))
                }

                Spacer()

                Text("Warehouse Desk")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 4. Payment Summary Card ──────────────────────────────────
    private var paymentSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PAYMENT SUMMARY")
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(Color(hex: 0x475569))
                .tracking(0.5)

            HStack {
                Text("Taxable Value (Subtotal)")
                    .font(.system(size: 12.5))
                    .foregroundColor(Color(hex: 0x64748B))
                Spacer()
                Text(CurrencyFormatter.formatINR(order.subtotal ?? (order.effectiveAmount / 1.18)))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: 0x0F172A))
            }

            HStack {
                Text("GST (18% Total)")
                    .font(.system(size: 12.5))
                    .foregroundColor(Color(hex: 0x64748B))
                Spacer()
                Text(CurrencyFormatter.formatINR(order.gst ?? (order.effectiveAmount - (order.effectiveAmount / 1.18))))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: 0x0F172A))
            }

            HStack {
                Text("Freight & Insurance")
                    .font(.system(size: 12.5))
                    .foregroundColor(Color(hex: 0x64748B))
                Spacer()
                Text("Complimentary")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(Color(hex: 0x2563EB))
            }

            Divider()
                .padding(.vertical, 2)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grand Total")
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))
                    Text("Inclusive of taxes & delivery")
                        .font(.system(size: 10.5))
                        .foregroundColor(Color(hex: 0x94A3B8))
                }

                Spacer()

                Text(CurrencyFormatter.formatINR(order.effectiveAmount))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    private func handleReorder() {
        guard let items = order.items, !items.isEmpty else { return }
        isReordering = true
        Task {
            var addedCount = 0
            for item in items {
                let dummyItem = InventoryItem(
                    _id: item.itemId ?? item.itemCode ?? UUID().uuidString,
                    itemId: item.itemId ?? item.itemCode,
                    itemCode: item.itemCode ?? "PART",
                    productName: item.displayName,
                    itemName: item.displayName,
                    primaryGroup: "General",
                    stockGroup: "General",
                    category: item.category ?? "Automotive Spares",
                    stockLevel: 100,
                    unitPrice: item.effectiveRate,
                    customerPrice: item.effectiveRate,
                    dealerPrice: item.effectiveRate,
                    retailPrice: item.effectiveRate
                )
                let success = await CartViewModel.shared.addToCart(product: dummyItem, quantity: item.effectiveQuantity)
                if success { addedCount += 1 }
            }
            await MainActor.run {
                isReordering = false
                if addedCount > 0 {
                    alertTitle = "Items Added to Cart"
                    alertMessage = "\(addedCount) item(s) from this order have been placed into your active cart."
                    reorderedSuccess = true
                } else {
                    alertTitle = "Reorder Failed"
                    alertMessage = "Unable to add items to cart."
                    reorderedSuccess = false
                }
                showAlert = true
            }
        }
    }
}
