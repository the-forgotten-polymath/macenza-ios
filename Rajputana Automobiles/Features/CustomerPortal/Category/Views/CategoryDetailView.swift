import SwiftUI

public struct CategoryDetailView: View {
    public let systemDomain: String
    @State public var selectedCategory: String

    @State private var allDomainItems: [InventoryItem] = []
    @State private var availableCategories: [String] = []
    @State private var filteredProducts: [InventoryItem] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = true
    @State private var selectedProduct: InventoryItem? = nil
    @State private var toastMessage: String? = nil
    @State private var showCartSheet: Bool = false

    public init(systemDomain: String, selectedCategory: String) {
        self.systemDomain = systemDomain
        _selectedCategory = State(initialValue: selectedCategory)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    public var body: some View {
        VStack(spacing: 0) {
            // Horizontal Category Selector
            if !availableCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableCategories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                                applyFilter()
                            } label: {
                                Text(cat)
                                    .font(AppTypography.subheadlineBold)
                                    .foregroundStyle(selectedCategory == cat ? Color.white : AppColors.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == cat ? AppColors.brandPrimary : AppColors.cardBackground)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedCategory == cat ? Color.clear : AppColors.borderLight, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(AppColors.cardBackground)
                Divider()
            }

            // In-Category Search
            SearchBarView(
                searchText: Binding(
                    get: { searchText },
                    set: {
                        searchText = $0
                        applyFilter()
                    }
                ),
                placeholder: "Search in \(selectedCategory)…"
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.background)

            // Products Grid
            if isLoading && filteredProducts.isEmpty {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<6, id: \.self) { _ in
                            ShimmerView(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(16)
                }
            } else if filteredProducts.isEmpty {
                ContentUnavailableView(
                    "No Products Found",
                    systemImage: "shippingbox",
                    description: Text("No items available in \(selectedCategory).")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredProducts) { item in
                            customerProductCard(item: item)
                                .onTapGesture {
                                    selectedProduct = item
                                }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle(selectedCategory)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCartSheet = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.brandPrimary)

                        if CartViewModel.shared.totalUnits > 0 {
                            Text("\(CartViewModel.shared.totalUnits)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppColors.brandPrimary)
                                .clipShape(Capsule())
                                .offset(x: 10, y: -8)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCartSheet) {
            CartFlowView()
        }
        .navigationDestination(item: $selectedProduct) { product in
            ProductDetailView(product: product)
        }
        .overlay(alignment: .bottom) {
            if let toast = toastMessage {
                Text(toast)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task {
            await loadData()
        }
    }

    @ViewBuilder
    private func customerProductCard(item: InventoryItem) -> some View {
        let inCart = CartViewModel.shared.items.first(where: { $0.id == item.id || $0.partNumber == item.itemCode })?.quantity ?? 0
        let isOutOfStock = item.effectiveStock <= 0

        VStack(alignment: .leading, spacing: 8) {
            // Image + Stock Badge
            ZStack(alignment: .topTrailing) {
                RemoteImageView(
                    imagePath: item.bestImage,
                    placeholderIcon: "car.side",
                    height: 120,
                    cornerRadius: 8
                )

                if isOutOfStock {
                    Text("Out of Stock")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.statusRedText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.statusRedBg)
                        .clipShape(Capsule())
                        .padding(6)
                } else if item.isLowStock {
                    Text("Few Left")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.amber)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.amberLight)
                        .clipShape(Capsule())
                        .padding(6)
                } else {
                    Text("In Stock")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.greenText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.greenBadgeBackground)
                        .clipShape(Capsule())
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.itemCode)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColors.brandPrimary)

                Text(item.displayName)
                    .font(AppTypography.subheadlineBold)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
                    .frame(height: 38, alignment: .topLeading)

                if let group = item.primaryGroup, !group.isEmpty {
                    Text(group)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(CurrencyFormatter.formatINR(item.effectivePrice))
                            .font(AppTypography.subheadlineBold)
                            .foregroundStyle(AppColors.textPrimary)

                        Text("+18% GST")
                            .font(.system(size: 9))
                            .foregroundStyle(AppColors.textMuted)
                    }

                    Spacer()

                    if isOutOfStock {
                        Text("Sold Out")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.surfaceVariant)
                            .clipShape(Capsule())
                    } else if inCart > 0 {
                        // Interactive Stepper exactly matching Android
                        HStack(spacing: 8) {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                CartViewModel.shared.updateQuantity(itemId: item.id, newQty: inCart - 1)
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.plain)

                            Text("\(inCart)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.white)

                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                Task {
                                    _ = await CartViewModel.shared.addToCart(product: item, quantity: 1)
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(AppColors.brandPrimary)
                        .clipShape(Capsule())
                        .shadow(color: AppColors.brandPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Button {
                            handleAddToCart(item)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "cart.badge.plus")
                                    .font(.system(size: 11, weight: .bold))
                                Text("ADD")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColors.brandPrimary)
                            .clipShape(Capsule())
                            .shadow(color: AppColors.brandPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.borderLight, lineWidth: 1)
        )
    }

    private func handleAddToCart(_ item: InventoryItem) {
        Task {
            let success = await CartViewModel.shared.addToCart(product: item, quantity: 1)
            await MainActor.run {
                withAnimation {
                    if success {
                        toastMessage = "Added 1x \(item.itemCode) to cart"
                    } else {
                        toastMessage = CartViewModel.shared.alertMessage ?? "Item out of stock"
                    }
                }
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation {
                    toastMessage = nil
                }
            }
        }
    }

    private func loadData() async {
        guard let session = SessionManager.shared.session else { return }

        isLoading = true
        do {
            let items = try await InventoryService.shared.fetchInventory(token: session.token)
            CartViewModel.shared.inventorySnapshot = items

            // Filter for domain
            let domainClean = systemDomain.trimmingCharacters(in: .whitespaces).lowercased()
            let matches = items.filter { item in
                let d = (item.systemDomain ?? "General").trimmingCharacters(in: .whitespaces).lowercased()
                return d == domainClean || (domainClean == "general" && d.isEmpty)
            }

            allDomainItems = matches

            // Extract unique categories in this domain
            var cats = Set<String>()
            for item in matches {
                let c = (item.category ?? item.stockGroup ?? "General").trimmingCharacters(in: .whitespaces)
                cats.insert(c.isEmpty ? "General" : c)
            }
            let sortedCats = Array(cats).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

            await MainActor.run {
                self.availableCategories = sortedCats
                if !sortedCats.contains(selectedCategory), let first = sortedCats.first {
                    self.selectedCategory = first
                }
                self.isLoading = false
                self.applyFilter()
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    private func applyFilter() {
        let catClean = selectedCategory.trimmingCharacters(in: .whitespaces).lowercased()
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()

        let categoryFiltered = allDomainItems.filter { item in
            let c = (item.category ?? item.stockGroup ?? "General").trimmingCharacters(in: .whitespaces).lowercased()
            return c == catClean || (catClean == "general" && c.isEmpty)
        }

        if query.isEmpty {
            filteredProducts = categoryFiltered
        } else {
            filteredProducts = categoryFiltered.filter { item in
                item.itemCode.lowercased().contains(query) ||
                item.displayName.lowercased().contains(query) ||
                (item.primaryGroup ?? "").lowercased().contains(query)
            }
        }
    }
}
