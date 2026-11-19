import SwiftUI

public struct CustomerOrderListView: View {
    @State private var orders: [OrderModel] = []
    @State private var filteredOrders: [OrderModel] = []
    @State private var inventoryMap: [String: InventoryItem] = [:]
    @State private var categories: [String] = []

    @State private var selectedFilter: String = "All"
    @State private var selectedCategory: String? = nil
    @State private var selectedDate: Date? = nil
    @State private var showDatePicker: Bool = false
    @State private var showCategorySheet: Bool = false
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var selectedOrder: OrderModel? = nil

    private let filterChips = ["All", "Confirmed", "Approved", "Synced", "Dispatched", "Delivered", "Cancelled"]

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── HEADER DOSSIER CARD ─────────────────────────────
                headerCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // ── SEARCH BAR & CALENDAR PICKER ───────────────────
                searchAndDateBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                // Active Date Filter Chip (if selected)
                if let date = selectedDate {
                    activeDateChip(date: date)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                // ── FILTER ROW: STATUS CHIPS & CATEGORY SELECTOR ───
                filterControlsRow
                    .padding(.bottom, 8)

                Divider()

                // ── CONTENT ────────────────────────────────────────
                if isLoading && orders.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(0..<5, id: \.self) { _ in
                                ShimmerView(height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(16)
                    }
                } else if let error = errorMessage, orders.isEmpty {
                    ContentUnavailableView(
                        "Unable to Load Orders",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if filteredOrders.isEmpty {
                    VStack(spacing: 14) {
                        Spacer()
                        Image(systemName: "shippingbox")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(hex: 0x94A3B8))
                        Text("No orders match your filters")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x475569))
                        Text("Try resetting your search query, status or spares category filter.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: 0x64748B))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button("Reset Filters") {
                            searchText = ""
                            selectedFilter = "All"
                            selectedCategory = nil
                            selectedDate = nil
                            applyFilters()
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LiquidTheme.electricBlue)
                        .padding(.top, 4)

                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredOrders) { order in
                                orderCard(order: order)
                                    .onTapGesture {
                                        selectedOrder = order
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .refreshable {
                        await loadOrders()
                    }
                }
            }
            .background(Color(hex: 0xF5F7FA).ignoresSafeArea())
            .navigationTitle("Orders")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedOrder) { order in
                CustomerOrderDetailView(order: order)
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
            .sheet(isPresented: $showCategorySheet) {
                categorySelectionSheet
            }
            .task {
                await loadOrders()
            }
        }
    }

    // ============================================================
    // HEADER CARD (Matching Android OrderListHeader)
    // ============================================================
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                Text("My Orders")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: 0x0F172A))

                Text("\(filteredOrders.count) of \(orders.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LiquidTheme.electricBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(LiquidTheme.electricBlue.opacity(0.12))
                    .clipShape(Capsule())

                Spacer()
            }

            Text("Track fulfilment status & GST tax invoices")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(hex: 0x64748B))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ============================================================
    // SEARCH BAR & DATE PICKER BUTTON
    // ============================================================
    private var searchAndDateBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: 0x94A3B8))

                TextField("Search by order ID, SKU, or item…", text: Binding(
                    get: { searchText },
                    set: {
                        searchText = $0
                        applyFilters()
                    }
                ))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: 0x0F172A))
                .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        applyFilters()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: 0x94A3B8))
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
            )

            Button {
                showDatePicker = true
            } label: {
                Image(systemName: selectedDate == nil ? "calendar" : "calendar.badge.clock")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(selectedDate == nil ? Color(hex: 0x475569) : LiquidTheme.electricBlue)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedDate == nil ? Color(hex: 0xE2E8F0) : LiquidTheme.electricBlue, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func activeDateChip(date: Date) -> some View {
        HStack {
            Image(systemName: "calendar")
                .font(.system(size: 11))
            Text("Date: \(formattedDate(date))")
                .font(.system(size: 11, weight: .semibold))

            Button {
                selectedDate = nil
                applyFilters()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundStyle(LiquidTheme.electricBlue)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(LiquidTheme.electricBlue.opacity(0.12))
        .clipShape(Capsule())
    }

    // ============================================================
    // FILTER CONTROLS (Status & Category Dropdowns matching Android OrderFilterRow)
    // ============================================================
    private var filterControlsRow: some View {
        HStack(spacing: 8) {
            // 1. Status Dropdown
            Menu {
                ForEach(["All Statuses", "Pending", "Confirmed", "Approved", "Rejected", "Delivered", "Cancelled"], id: \.self) { status in
                    Button {
                        selectedFilter = status == "All Statuses" ? "All" : status
                        applyFilters()
                    } label: {
                        HStack {
                            Text(status)
                            if (selectedFilter == "All" && status == "All Statuses") || selectedFilter == status {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedFilter == "All" ? "All Statuses" : selectedFilter)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x334155))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: 0x64748B))
                }
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
            }

            // 2. Category Dropdown
            Menu {
                Button {
                    selectedCategory = nil
                    applyFilters()
                } label: {
                    HStack {
                        Text("All Categories")
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                ForEach(categories, id: \.self) { cat in
                    Button {
                        selectedCategory = cat
                        applyFilters()
                    } label: {
                        HStack {
                            Text(cat)
                            if selectedCategory == cat {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategory ?? "All Categories")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x334155))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: 0x64748B))
                }
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // ============================================================
    // ORDER CARD (Matching Android OrderCard.kt)
    // ============================================================
    @ViewBuilder
    private func orderCard(order: OrderModel) -> some View {
        let firstItem = order.items?.first
        let inventoryItem = firstItem.flatMap { item in
            inventoryMap[(item.itemCode ?? item.itemId ?? "").trimmingCharacters(in: .whitespaces).lowercased()]
        }
        let imageUrl = inventoryItem?.bestImage ?? ""
        let displayName = firstItem?.displayName ?? "Order Items"

        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Thumbnail + Product Name + Date & Status Ref + Arrow
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: 0xF1F5F9))
                        .frame(width: 48, height: 48)

                    if !imageUrl.isEmpty {
                        RemoteImageView(urlString: imageUrl, contentMode: .fit, placeholderIcon: "car.side.fill")
                            .frame(width: 42, height: 42)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: 0x64748B))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(displayName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0F172A))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(order.effectiveDate.isEmpty ? "Date unavailable" : order.effectiveDate)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: 0x64748B))

                        Text("•")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: 0x94A3B8))

                        Text("Ref: \(order.displayStatus)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(order.displayStatus.lowercased().contains("pend") ? Color(hex: 0xB7791F) : Color(hex: 0x64748B))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x94A3B8))
            }

            // Divider Line
            Rectangle()
                .fill(Color(hex: 0xF0F2F5))
                .frame(height: 1)

            // Middle Row: Order ID Pill + Status Badge with dot
            HStack {
                Text(order.displayOrderNumber)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LiquidTheme.electricBlue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(LiquidTheme.electricBlue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                statusBadgeWithDot(order.displayStatus)
            }

            // Bottom Row: Rounded Container with Item Count + Total INR Amount
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: 0x64748B))

                    let count = order.itemCount ?? order.items?.count ?? 0
                    Text("\(count) Item\(count != 1 ? "s" : "")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x0F172A))
                }

                Spacer()

                Text(CurrencyFormatter.formatINR(order.effectiveAmount))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: 0x0F172A))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: 0xF8FAFC))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    private func statusBadgeWithDot(_ status: String) -> some View {
        let s = status.lowercased()
        let isGreen = s.contains("deliver") || s.contains("approv") || s.contains("confirm")
        let isRed = s.contains("cancel") || s.contains("reject")
        let bg = isGreen ? Color(hex: 0xE8F8F0) : (isRed ? Color(hex: 0xFEE2E2) : Color(hex: 0xFFF4E5))
        let fg = isGreen ? Color(hex: 0x0F9F68) : (isRed ? Color(hex: 0xDC2626) : Color(hex: 0xB7791F))

        return HStack(spacing: 5) {
            Circle()
                .fill(fg)
                .frame(width: 6, height: 6)

            Text(status)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(fg)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(bg)
        .clipShape(Capsule())
    }

    // ============================================================
    // CATEGORY BOTTOM SHEET (Matching Android CategoryBottomSheet.kt)
    // ============================================================
    private var categorySelectionSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Select Spares Category")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0F172A))

                    Text("Filter dispatch lines by ERP inventory module")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: 0x64748B))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider()

                List {
                    // "All Categories" option
                    Button {
                        selectedCategory = nil
                        applyFilters()
                        showCategorySheet = false
                    } label: {
                        HStack {
                            Text("All Categories")
                                .font(.system(size: 14, weight: selectedCategory == nil ? .bold : .regular))
                                .foregroundStyle(selectedCategory == nil ? LiquidTheme.electricBlue : Color(hex: 0x0F172A))

                            Spacer()

                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(LiquidTheme.electricBlue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(selectedCategory == nil ? LiquidTheme.electricBlue.opacity(0.06) : Color.white)

                    ForEach(categories, id: \.self) { cat in
                        Button {
                            selectedCategory = cat
                            applyFilters()
                            showCategorySheet = false
                        } label: {
                            HStack {
                                Text(cat)
                                    .font(.system(size: 14, weight: selectedCategory == cat ? .bold : .regular))
                                    .foregroundStyle(selectedCategory == cat ? LiquidTheme.electricBlue : Color(hex: 0x0F172A))

                                Spacer()

                                if selectedCategory == cat {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(LiquidTheme.electricBlue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(selectedCategory == cat ? LiquidTheme.electricBlue.opacity(0.06) : Color.white)
                    }
                }
                .listStyle(.plain)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showCategorySheet = false
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LiquidTheme.electricBlue)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // ============================================================
    // DATE PICKER SHEET
    // ============================================================
    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Filter by Date",
                    selection: Binding(
                        get: { selectedDate ?? Date() },
                        set: { selectedDate = $0 }
                    ),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()

                HStack(spacing: 12) {
                    Button("Clear Date Filter") {
                        selectedDate = nil
                        applyFilters()
                        showDatePicker = false
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: 0xDC2626))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: 0xFEE2E2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button("Apply Filter") {
                        if selectedDate == nil {
                            selectedDate = Date()
                        }
                        applyFilters()
                        showDatePicker = false
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(LiquidTheme.electricBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Select Order Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        showDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // ============================================================
    // DATA LOADING & FILTERING
    // ============================================================
    private func loadOrders() async {
        guard let session = SessionManager.shared.session else { return }

        isLoading = true
        errorMessage = nil

        do {
            async let fetchedOrders = OrderService.shared.fetchOrders(
                token: session.token,
                customerCode: session.customerCode,
                customerEmail: session.customerEmail
            )
            async let fetchedInventory = InventoryService.shared.fetchInventory(token: session.token)

            let (ordersList, inventoryList) = try await (fetchedOrders, (try? fetchedInventory) ?? [])

            var map: [String: InventoryItem] = [:]
            for item in inventoryList {
                for key in [item.itemCode, item.id, item.mongoId].compactMap({ $0?.trimmingCharacters(in: .whitespaces).lowercased() }) where !key.isEmpty {
                    map[key] = item
                }
            }

            // Extract distinct categories from inventory (with fallback to orders)
            var catSet = Set<String>()
            for item in inventoryList {
                if let cat = item.category?.trimmingCharacters(in: .whitespaces), !cat.isEmpty {
                    catSet.insert(cat)
                } else if let grp = item.stockGroup?.trimmingCharacters(in: .whitespaces), !grp.isEmpty {
                    catSet.insert(grp)
                }
            }

            if catSet.isEmpty {
                for order in ordersList {
                    for line in order.items ?? [] {
                        if let name = line.name, !name.isEmpty {
                            // line items might not have category, but if present:
                        }
                    }
                }
            }

            let sortedCats = catSet.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

            await MainActor.run {
                self.orders = ordersList.sorted { ($0.date ?? "") > ($1.date ?? "") }
                self.inventoryMap = map
                self.categories = sortedCats
                self.applyFilters()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func applyFilters() {
        var list = orders

        // Status Filter
        if selectedFilter != "All" {
            let filterClean = selectedFilter.lowercased()
            list = list.filter { $0.displayStatus.lowercased().contains(filterClean) }
        }

        // Category Filter
        if let cat = selectedCategory, !cat.isEmpty {
            let catClean = cat.lowercased()
            list = list.filter { order in
                guard let items = order.items else { return false }
                return items.contains { lineItem in
                    let key = (lineItem.itemCode ?? lineItem.itemId ?? "").trimmingCharacters(in: .whitespaces).lowercased()
                    if let inv = inventoryMap[key] {
                        let invCat = (inv.category ?? inv.stockGroup ?? "").lowercased()
                        if invCat == catClean { return true }
                    }
                    return false
                }
            }
        }

        // Date Filter
        if let targetDate = selectedDate {
            list = list.filter { order in
                guard let orderDate = parseDate(order.effectiveDate) else { return false }
                return Calendar.current.isDate(orderDate, inSameDayAs: targetDate)
            }
        }

        // Search Query
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter { order in
                if order.displayOrderNumber.lowercased().contains(q) { return true }
                if order.effectiveDate.lowercased().contains(q) { return true }
                if let items = order.items {
                    for item in items {
                        if item.displayName.lowercased().contains(q) { return true }
                        if (item.itemCode ?? "").lowercased().contains(q) { return true }
                    }
                }
                return false
            }
        }

        filteredOrders = list
    }

    private func parseDate(_ dateStr: String) -> Date? {
        if dateStr.isEmpty { return nil }
        let formatters: [DateFormatter] = [
            {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "dd/MM/yyyy"
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "dd-MM-yyyy"
                return df
            }()
        ]
        for f in formatters {
            if let d = f.date(from: dateStr) { return d }
        }
        return nil
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
