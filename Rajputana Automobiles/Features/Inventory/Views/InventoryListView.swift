import SwiftUI

public struct InventoryListView: View {
    @State private var viewModel = InventoryViewModel()
    public var onSelectItem: ((String) -> Void)? = nil

    @State private var selectedItemForQuickEdit: InventoryItem? = nil
    @State private var selectedItemForDelete: InventoryItem? = nil
    @State private var isDeletingItem: Bool = false
    @State private var showFiltersSheet: Bool = ProcessInfo.processInfo.arguments.contains("-openFilter")
    @State private var selectedDetailItemId: String? = nil

    public init(onSelectItem: ((String) -> Void)? = nil) {
        self.onSelectItem = onSelectItem
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: 0xF4F6F9).ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        // ── WAREHOUSE CATALOG HEADER CARD ─────────────────
                        warehouseHeaderCard
                            .padding(.top, 4)

                        // ── TOP GROUPS HORIZONTAL CHIPS ───────────────────
                        topGroupsChipsRow

                        // ── SEARCH & FILTERS BAR ──────────────────────────
                        searchAndFiltersRow

                        // ── INVENTORY ITEMS ───────────────────────────────
                        if viewModel.isLoading && viewModel.items.isEmpty {
                            ForEach(0..<6, id: \.self) { _ in
                                ShimmerBox(height: 140, cornerRadius: 16)
                                    .padding(.horizontal, 12)
                            }
                        } else if viewModel.filteredItems.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(viewModel.visibleItems) { item in
                                inventoryCard(item)
                                    .onAppear {
                                        if item.id == viewModel.visibleItems.last?.id {
                                            viewModel.loadMore()
                                        }
                                    }
                            }

                            if viewModel.hasMore {
                                Button(action: { viewModel.loadMore() }) {
                                    HStack(spacing: 6) {
                                        ProgressView().scaleEffect(0.8)
                                        Text("Loading more items...")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(hex: 0x64748B))
                                    }
                                    .padding(.vertical, 16)
                                }
                            }
                        }

                        Spacer().frame(height: 70)
                    }
                }
                .refreshable {
                    await viewModel.loadInventory(forceRefresh: true)
                }

                // ── DELETE DIALOG ─────────────────────────────────────────
                if let itemToDelete = selectedItemForDelete {
                    DeleteInventoryDialog(
                        item: itemToDelete,
                        isDeleting: isDeletingItem,
                        onCancel: { selectedItemForDelete = nil },
                        onConfirm: {
                            Task {
                                isDeletingItem = true
                                let success = await viewModel.deleteItem(id: itemToDelete.id)
                                isDeletingItem = false
                                if success {
                                    selectedItemForDelete = nil
                                }
                            }
                        }
                    )
                }
            }
            .navigationTitle("Rajputana Automobiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: 0x0F172A))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 17))
                            .foregroundColor(Color(hex: 0x0F172A))

                        Circle()
                            .fill(Color(hex: 0x2563EB))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Text("3")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 5, y: -5)
                    }
                }
            }
            .task {
                if viewModel.items.isEmpty {
                    await viewModel.loadInventory()
                }
            }
            .sheet(isPresented: $showFiltersSheet) {
                InventoryFilterSheet(
                    viewModel: viewModel,
                    onApply: {
                        viewModel.visibleCount = 30
                    }
                )
                .presentationDetents([.fraction(0.65), .large])
                .presentationDragIndicator(.hidden)
            }
            .sheet(item: $selectedItemForQuickEdit) { item in
                QuickEditInventorySheet(item: item) { _ in
                    Task { await viewModel.loadInventory(forceRefresh: true) }
                }
            }
            .navigationDestination(item: $selectedDetailItemId) { id in
                InventoryDetailView(itemId: id, canEdit: true)
            }
        }
    }

    // ── WAREHOUSE HEADER CARD ─────────────────────────────────
    private var warehouseHeaderCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("WAREHOUSE CATALOG")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundColor(Color(hex: 0x2563EB))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0xEFF6FF))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text("Stock Management")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))
                        .padding(.top, 2)

                    Text("Monitor live warehouse stock levels, track catalog availability, and manage distribution in real-time.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x64748B))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCount(viewModel.items.count))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))

                    Text("Total SKUs")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x64748B))
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
    }

    // ── TOP GROUPS HORIZONTAL CHIPS ───────────────────────────
    private var topGroupsChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.topGroupsWithCounts, id: \.label) { group in
                    let isSelected = (group.label == "All" && viewModel.selectedTopGroup == nil) ||
                                     (viewModel.selectedTopGroup == group.label)

                    Button {
                        if group.label == "All" {
                            viewModel.selectedTopGroup = nil
                        } else {
                            viewModel.selectedTopGroup = group.label
                        }
                        viewModel.visibleCount = 30
                    } label: {
                        HStack(spacing: 6) {
                            Text(formatGroupLabel(group.label))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isSelected ? .white : Color(hex: 0x0F172A))
                                .lineLimit(1)

                            Text("\(group.count)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isSelected ? .white : Color(hex: 0x64748B))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.white.opacity(0.25) : Color(hex: 0xE2E8F0))
                                )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color(hex: 0x2563EB) : Color.white)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    // ── SEARCH & FILTERS BAR ──────────────────────────────────
    private var searchAndFiltersRow: some View {
        HStack(spacing: 10) {
            // Search Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: 0x94A3B8))

                TextField("Search by product name...", text: $viewModel.searchQuery)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .autocorrectionDisabled()

                if !viewModel.searchQuery.isEmpty {
                    Button(action: { viewModel.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: 0x94A3B8))
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Blue Filters Button
            Button(action: { showFiltersSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .bold))

                    Text("Filters")
                        .font(.system(size: 14, weight: .bold))

                    if viewModel.activeFilterCount > 0 {
                        Text("\(viewModel.activeFilterCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: 0x2563EB))
                            .frame(width: 16, height: 16)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(Color(hex: 0x2563EB))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
    }

    // ── INVENTORY ITEM CARD ───────────────────────────────────
    private func inventoryCard(_ item: InventoryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1: Code chip + Group chip + Kebab menu
            HStack(spacing: 6) {
                Text(item.itemCode)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(item.inventoryCategory)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: 0x64748B))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xF1F5F9))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .lineLimit(1)

                Spacer()

                Menu {
                    Button {
                        selectedItemForQuickEdit = item
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        selectedItemForDelete = item
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }

            // Row 2: Thumbnail + Name
            HStack(alignment: .center, spacing: 12) {
                let bestImg = item.bestImage
                if !bestImg.isEmpty, let url = URL(string: bestImg) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        default:
                            placeholderImage
                        }
                    }
                    .frame(width: 56, height: 56)
                } else {
                    placeholderImage
                }

                Text(item.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()
            }

            Divider().background(Color(hex: 0xE2E8F0))

            // Row 3: Stock level + Unit price
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("STOCK LEVEL")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .tracking(0.5)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(item.stockLevelDisplay)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(item.isOutOfStock ? Color(hex: 0xDC2626) : Color(hex: 0x0F172A))

                        Text(item.unit?.isEmpty == false ? item.unit! : "pc")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(Color(hex: 0x64748B))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("UNIT PRICE")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .tracking(0.5)

                    Text(formatPrice(item.unitPrice ?? 0.0))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: 0x2563EB))
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            if let onSelectItem = onSelectItem {
                onSelectItem(item.id)
            } else {
                selectedDetailItemId = item.id
            }
        }
    }

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: 0xF1F5F9))
                .frame(width: 56, height: 56)

            Image(systemName: "shippingbox.fill")
                .font(.system(size: 22))
                .foregroundColor(Color(hex: 0x2563EB))
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 30)

            Image(systemName: "shippingbox")
                .font(.system(size: 44))
                .foregroundColor(Color(hex: 0x94A3B8))

            Text("No inventory items found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: 0x0F172A))

            Text("Try clearing active filters or searching for another keyword.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0x64748B))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Reset Filters") {
                viewModel.resetFilters()
                viewModel.selectedTopGroup = nil
                viewModel.searchQuery = ""
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color(hex: 0x2563EB))
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // ── FORMATTERS ────────────────────────────────────────────
    private func formatCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    private func formatPrice(_ price: Double) -> String {
        if price == 0 {
            return "₹0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "₹\(Int(price))"
    }

    private func formatGroupLabel(_ label: String) -> String {
        let words = label.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.count > 2 {
            return words.prefix(2).joined(separator: " ") + "..."
        }
        return label
    }
}
