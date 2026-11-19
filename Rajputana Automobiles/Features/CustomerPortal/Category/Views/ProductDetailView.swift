import SwiftUI

public struct ProductDetailView: View {
    public let product: InventoryItem
    @Environment(\.dismiss) private var dismiss

    @State private var selectedImageIndex: Int = 0
    @State private var isAdding: Bool = false
    @State private var showCartSheet: Bool = false
    @State private var toastMessage: String? = nil

    public init(product: InventoryItem) {
        self.product = product
    }

    private var maxAvailable: Int {
        return max(0, Int(product.effectiveStock))
    }

    private var gstPercent: Int {
        return product.gst ?? 18
    }

    private var gstAmount: Double {
        return round((product.effectivePrice * (Double(gstPercent) / 100.0)) * 100) / 100.0
    }

    private var unitPriceWithGst: Double {
        return product.effectivePrice + gstAmount
    }

    private var galleryImages: [String] {
        var imgs: [String] = []
        let best = product.bestImage.trimmingCharacters(in: .whitespaces)
        if !best.isEmpty { imgs.append(best) }
        if let extra = product.images {
            for img in extra {
                let clean = img.trimmingCharacters(in: .whitespaces)
                if !clean.isEmpty && !imgs.contains(clean) {
                    imgs.append(clean)
                }
            }
        }
        return imgs.isEmpty ? [""] : imgs
    }

    private var cartItem: CartApiItem? {
        CartViewModel.shared.items.first {
            $0.partNumber.caseInsensitiveCompare(product.itemCode) == .orderedSame ||
            $0.id == product.id
        }
    }

    private var quantityInCart: Int {
        cartItem?.quantity ?? 0
    }

    private var warrantyBadge: String? {
        product.specifications?.first { $0.localizedCaseInsensitiveContains("warranty") }
    }

    private var certBadge: String? {
        product.specifications?.first {
            $0.localizedCaseInsensitiveContains("certified") ||
            $0.localizedCaseInsensitiveContains("iso") ||
            $0.localizedCaseInsensitiveContains("oem")
        }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // ── MAIN IMAGE HERO & CAROUSEL ─────────────────────
                imageGallerySection
                    .padding(.horizontal, 16)

                // ── PRODUCT TITLE & BRAND ──────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(product.itemCode)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LiquidTheme.electricBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(LiquidTheme.electricBlue.opacity(0.12))
                            .clipShape(Capsule())

                        if let brand = product.primaryGroup ?? product.stockGroup, !brand.isEmpty {
                            Text(brand)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x475569))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: 0xF1F5F9))
                                .clipShape(Capsule())
                        }

                        Spacer()
                    }

                    Text(product.displayName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0F172A))
                        .lineSpacing(4)

                    // Category & Vehicle segment hierarchy line
                    let catLine = [product.systemDomain, product.category ?? product.stockGroup]
                        .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                        .joined(separator: " / ")
                    if !catLine.isEmpty {
                        Text(catLine)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: 0x64748B))
                    }

                    // Feature / Warranty Badges
                    if warrantyBadge != nil || certBadge != nil {
                        HStack(spacing: 8) {
                            if let w = warrantyBadge {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 11))
                                    Text(w)
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundStyle(Color(hex: 0x0F9F68))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: 0xE8F8F0))
                                .clipShape(Capsule())
                            }

                            if let c = certBadge {
                                HStack(spacing: 4) {
                                    Image(systemName: "rosette")
                                        .font(.system(size: 11))
                                    Text(c)
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundStyle(LiquidTheme.electricBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(LiquidTheme.electricBlue.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 16)

                // ── PRICING CARD ───────────────────────────────────
                VStack(spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("DEALER NET PRICE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: 0x64748B))
                                .tracking(0.5)

                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(CurrencyFormatter.formatINR(product.effectivePrice))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(LiquidTheme.electricBlue)

                                Text("Incl. \(gstPercent)% GST")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color(hex: 0x64748B))
                            }
                        }

                        Spacer()

                        // In-place Mini Stepper / Add button
                        miniCartActionView
                    }

                    Divider()

                    HStack {
                        Text("GST Breakdown:")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(hex: 0x64748B))
                        Spacer()
                        Text("CGST \(gstPercent/2)% + SGST \(gstPercent/2)% (\(CurrencyFormatter.formatINR(gstAmount)))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x475569))
                            .monospacedDigit()
                    }
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
                .padding(.horizontal, 16)

                // ── SPECIFICATIONS TABLE ───────────────────────────
                VStack(alignment: .leading, spacing: 14) {
                    Text("Product Specifications")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0F172A))

                    VStack(spacing: 10) {
                        specRow(label: "Part Number / SKU", value: product.itemCode)
                        Divider()
                        specRow(label: "System Domain", value: product.systemDomain ?? "General")
                        Divider()
                        specRow(label: "Category", value: product.category ?? product.stockGroup ?? "General")
                        Divider()
                        specRow(label: "Stock Group", value: product.stockGroup ?? "Automotive Spares")
                        Divider()
                        specRow(label: "Vehicle Segment", value: product.vehicleSegment ?? "Commercial & Passenger")
                        Divider()
                        specRow(label: "Packaging Unit", value: product.unit ?? "Pcs")

                        if let warehouse = product.warehouse, !warehouse.isEmpty {
                            Divider()
                            specRow(label: "Warehouse", value: warehouse)
                        }

                        if let desc = product.description, !desc.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(Color(hex: 0x64748B))
                                Text(desc)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color(hex: 0x0F172A))
                                    .lineSpacing(3)
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
                .padding(.horizontal, 16)

                Spacer(minLength: 80)
            }
            .padding(.vertical, 14)
        }
        .background(Color(hex: 0xF5F7FA).ignoresSafeArea())
        .navigationTitle(product.itemCode)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    // Share Sheet
                    ShareLink(
                        item: "\(product.displayName) (\(product.itemCode)) - \(CurrencyFormatter.formatINR(product.effectivePrice)) | Rajputana Automobiles"
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: 0x0F172A))
                    }

                    // Cart Icon with Badge
                    Button {
                        showCartSheet = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(LiquidTheme.electricBlue)

                            if CartViewModel.shared.totalUnits > 0 {
                                Text("\(CartViewModel.shared.totalUnits)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: 0xDC2626))
                                    .clipShape(Capsule())
                                    .offset(x: 10, y: -8)
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomStickyBar
        }
        .sheet(isPresented: $showCartSheet) {
            CartFlowView()
        }
        .overlay(alignment: .bottom) {
            if let toast = toastMessage {
                Text(toast)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // ============================================================
    // IMAGE GALLERY (Carousel + 64x64 Thumbnails matching Android)
    // ============================================================
    private var imageGallerySection: some View {
        VStack(spacing: 12) {
            // Main Image
            ZStack(alignment: .topTrailing) {
                let currentUrl = galleryImages.indices.contains(selectedImageIndex) ? galleryImages[selectedImageIndex] : galleryImages.first ?? ""

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(height: 260)

                    if !currentUrl.isEmpty {
                        RemoteImageView(
                            urlString: currentUrl,
                            contentMode: .fit,
                            placeholderIcon: "car.side.fill",
                            height: 250,
                            cornerRadius: 14
                        )
                        .padding(8)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "car.side.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(hex: 0x94A3B8))
                            Text("No Photo Available")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: 0x64748B))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )

                // Stock Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(product.effectiveStock > 0 ? Color(hex: 0x0F9F68) : Color(hex: 0xDC2626))
                        .frame(width: 6, height: 6)

                    Text(product.effectiveStock > 0 ? "In Stock (\(maxAvailable))" : "Out of Stock")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(product.effectiveStock > 0 ? Color(hex: 0x0F9F68) : Color(hex: 0xDC2626))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(product.effectiveStock > 0 ? Color(hex: 0xE8F8F0) : Color(hex: 0xFEE2E2))
                .clipShape(Capsule())
                .padding(14)
            }

            // Thumbnail strip (Matching Android 64x64 tiles with blue selector)
            if galleryImages.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(galleryImages.indices, id: \.self) { idx in
                            let isSelected = selectedImageIndex == idx
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedImageIndex = idx
                                }
                            } label: {
                                RemoteImageView(
                                    urlString: galleryImages[idx],
                                    contentMode: .fit,
                                    placeholderIcon: "photo",
                                    height: 56,
                                    cornerRadius: 8
                                )
                                .frame(width: 64, height: 64)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? LiquidTheme.electricBlue : Color(hex: 0xE2E8F0), lineWidth: isSelected ? 2 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // ============================================================
    // MINI CART ACTION (In-place on Price Card)
    // ============================================================
    @ViewBuilder
    private var miniCartActionView: some View {
        if quantityInCart > 0 {
            HStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    adjustQuantity(-1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 32, height: 32)
                }

                Text("\(quantityInCart)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                    .monospacedDigit()

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    adjustQuantity(1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 32, height: 32)
                }
                .disabled(quantityInCart >= maxAvailable)
            }
            .padding(.horizontal, 6)
            .frame(height: 38)
            .background(LiquidTheme.electricBlue)
            .clipShape(Capsule())
        } else {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                adjustQuantity(1)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Add to Cart")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(maxAvailable > 0 ? LiquidTheme.electricBlue : Color(hex: 0x94A3B8))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(maxAvailable <= 0)
        }
    }

    // ============================================================
    // BOTTOM STICKY BAR (Matching Android ProductPurchaseBar)
    // ============================================================
    private var bottomStickyBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SUBTOTAL")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(hex: 0x64748B))
                    .tracking(0.5)

                let count = max(1, quantityInCart)
                Text(CurrencyFormatter.formatINR(product.effectivePrice * Double(count)))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x0F172A))
            }

            Spacer()

            if quantityInCart > 0 {
                HStack(spacing: 16) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        adjustQuantity(-1)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 40, height: 44)
                    }

                    Text("\(quantityInCart)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                        .monospacedDigit()

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        adjustQuantity(1)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 40, height: 44)
                    }
                    .disabled(quantityInCart >= maxAvailable)
                }
                .padding(.horizontal, 10)
                .frame(height: 46)
                .background(LiquidTheme.electricBlue)
                .clipShape(Capsule())
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    adjustQuantity(1)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 15))
                        Text(maxAvailable > 0 ? "Add to Cart" : "Out of Stock")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 22)
                    .frame(height: 46)
                    .background(maxAvailable > 0 ? LiquidTheme.electricBlue : Color(hex: 0x94A3B8))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(maxAvailable <= 0)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -2)
        )
    }

    @ViewBuilder
    private func specRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(hex: 0x64748B))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: 0x0F172A))
        }
    }

    private func adjustQuantity(_ delta: Int) {
        let newQty = max(0, quantityInCart + delta)
        if newQty == 0 {
            if let item = cartItem {
                CartViewModel.shared.removeItem(itemId: item.id)
                showToast("Removed from cart")
            }
        } else if quantityInCart == 0 {
            Task {
                let success = await CartViewModel.shared.addToCart(product: product, quantity: 1)
                await MainActor.run {
                    if success {
                        showToast("Added \(product.itemCode) to cart")
                    } else {
                        showToast(CartViewModel.shared.alertMessage ?? "Unable to add item")
                    }
                }
            }
        } else {
            if let item = cartItem {
                CartViewModel.shared.updateQuantity(itemId: item.id, newQty: newQty)
            }
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation { toastMessage = nil }
            }
        }
    }
}
