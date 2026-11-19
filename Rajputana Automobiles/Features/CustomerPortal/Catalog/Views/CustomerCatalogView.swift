import SwiftUI

public struct CustomerCatalogView: View {
    @State private var viewModel = CatalogViewModel()
    @State private var selectedProduct: InventoryItem? = nil
    public var onSelectProduct: ((String) -> Void)? = nil
    public var onViewAllCategories: (() -> Void)? = nil
    public var onOpenCart: (() -> Void)? = nil

    public init(
        onSelectProduct: ((String) -> Void)? = nil,
        onViewAllCategories: (() -> Void)? = nil,
        onOpenCart: (() -> Void)? = nil
    ) {
        self.onSelectProduct = onSelectProduct
        self.onViewAllCategories = onViewAllCategories
        self.onOpenCart = onOpenCart
    }

    public var body: some View {
        ZStack {
            Color(hex: 0xF8FAFC).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    // 1. Search Bar matching Android CatalogSearchBar
                    searchBar
                        .padding(.top, 8)

                    // 2. Hero Card matching Android CatalogHeroCard
                    heroCard

                    // 3. Shop by Category Row matching Android CategoryRow
                    shopByCategoryRow

                    // 4. 2-Column Product Grid matching Android ProductCardItem
                    if viewModel.isLoading && viewModel.allItems.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(0..<6, id: \.self) { _ in
                                ShimmerBox(height: 230, cornerRadius: 18)
                            }
                        }
                    } else if viewModel.featuredProducts.isEmpty {
                        VStack(spacing: 12) {
                            Spacer().frame(height: 40)
                            Image(systemName: "car.2.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Color(hex: 0x94A3B8))
                            Text("No products found")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x0F172A))
                            Spacer().frame(height: 40)
                        }
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(viewModel.featuredProducts) { product in
                                productCard(product)
                            }
                        }
                    }

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 10)
            }
            .refreshable {
                await viewModel.loadCatalog()
            }
        }
        .navigationDestination(item: $selectedProduct) { product in
            ProductDetailView(product: product)
        }
        .task {
            await viewModel.loadCatalog()
        }
    }

    // ── Search Bar ──────────────────────────────────────────────
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0x94A3B8))

            TextField("Search catalog, part numbers, OEM...", text: $viewModel.searchQuery)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: 0x0F172A))
                .autocorrectionDisabled()

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: 0x94A3B8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── Hero Card ───────────────────────────────────────────────
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Product Catalog")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))

            Text("Browse genuine & aftermarket auto spare parts. Search by Part Number, OEM Code or name.")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0x64748B))
                .lineSpacing(3)
                .padding(.top, 5)

            HStack(spacing: 8) {
                // 100% Genuine Chip
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x2563EB))
                    Text("100% Genuine")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: 0x1E293B))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.85))
                .clipShape(Capsule())

                // Fast Delivery Chip
                HStack(spacing: 5) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x2563EB))
                    Text("Fast Delivery")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: 0x1E293B))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.85))
                .clipShape(Capsule())
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: 0xE8F0FF), Color(hex: 0xEFF5FF)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0xDCE6FB), lineWidth: 1)
        )
    }

    // ── Shop by Category Row ────────────────────────────────────
    private var shopByCategoryRow: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                Capsule()
                    .fill(Color(hex: 0x2563EB))
                    .frame(width: 3.5, height: 16)

                Text("Shop by Category")
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Spacer()

                Button {
                    onViewAllCategories?()
                } label: {
                    HStack(spacing: 3) {
                        Text("View All")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: 0x2563EB))
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.categoryPills) { pill in
                        let isSelected = viewModel.selectedFeaturedCategory == pill.name
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                if isSelected {
                                    viewModel.selectedFeaturedCategory = "All"
                                } else {
                                    viewModel.selectedFeaturedCategory = pill.name
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(pill.name)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                                    .foregroundColor(isSelected ? .white : Color(hex: 0x1E293B))

                                Text("\(pill.count)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(isSelected ? .white : Color(hex: 0x64748B))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? Color.white.opacity(0.25) : Color(hex: 0xF1F5F9))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isSelected ? Color(hex: 0x2563EB) : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isSelected ? Color.clear : Color(hex: 0xE2E8F0), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // ── Product Card matching Android ProductCardItem ────────────
    private func productCard(_ product: InventoryItem) -> some View {
        let inCart = CartViewModel.shared.items.first(where: {
            $0.id == product.id || $0.partNumber.lowercased() == product.itemCode.lowercased()
        })?.quantity ?? 0

        return Button {
            selectedProduct = product
            onSelectProduct?(product.id)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Photo container (aspect ratio ~1.3)
                ZStack {
                    Color(hex: 0xF1F5F9)

                    if !product.bestImage.isEmpty {
                        RemoteImageView(urlString: product.bestImage, contentMode: .fill, placeholderIcon: "photo.fill")
                    } else {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: 0x2563EB))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 125)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer().frame(height: 8)

                // OEM code
                Text("OEM: \(product.itemCode)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))
                    .lineLimit(1)

                Spacer().frame(height: 4)

                // Product Name (2 lines reserved)
                Text(product.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 38, alignment: .topLeading)

                // Category line
                let cat = product.category ?? product.primaryGroup ?? product.stockGroup ?? ""
                if !cat.isEmpty {
                    Text(cat)
                        .font(.system(size: 11.5))
                        .foregroundColor(Color(hex: 0x64748B))
                        .lineLimit(1)
                        .padding(.top, 2)
                }

                Spacer().frame(height: 8)

                // Price + Cart Button
                HStack(alignment: .center) {
                    Text(CurrencyFormatter.formatINR(product.effectivePrice))
                        .font(.system(size: 15.5, weight: .heavy))
                        .foregroundColor(Color(hex: 0x0F172A))
                        .lineLimit(1)

                    Spacer()

                    if inCart > 0 {
                        // Stepper [- count +]
                        HStack(spacing: 8) {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                CartViewModel.shared.updateQuantity(itemId: product.id, newQty: inCart - 1)
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                            }
                            .buttonStyle(.plain)

                            Text("\(inCart)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)

                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                Task {
                                    _ = await CartViewModel.shared.addToCart(product: product, quantity: 1)
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(hex: 0x2563EB))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // + Add button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            Task {
                                _ = await CartViewModel.shared.addToCart(product: product, quantity: 1)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "cart.badge.plus")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Add")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color(hex: 0x2563EB))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: 0xE8EDF3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
