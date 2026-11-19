import SwiftUI

public struct OrderListView: View {
    @State private var viewModel = OrderViewModel()
    public var onSelectOrder: ((OrderModel) -> Void)? = nil

    @State private var showDatePickerSheet: Bool = false
    @State private var tempDatePickerDate: Date = Date()

    public init(onSelectOrder: ((OrderModel) -> Void)? = nil) {
        self.onSelectOrder = onSelectOrder
    }

    public var body: some View {
        ZStack {
            Color(hex: 0xF8FAFC).ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.orders.isEmpty {
                    ordersLoadingSkeleton
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            // ── 1. Management Header Card ───────────────────
                            ordersHeaderCard
                                .padding(.horizontal, 14)
                                .padding(.top, 12)

                            // ── 2. Search Field ─────────────────────────────
                            ordersSearchField
                                .padding(.horizontal, 14)

                            // ── 3. Filters Row ──────────────────────────────
                            ordersFilterRow
                                .padding(.horizontal, 14)

                            // ── 4. Orders List ──────────────────────────────
                            if viewModel.filteredOrders.isEmpty {
                                emptyOrdersState
                                    .padding(.top, 36)
                            } else {
                                ForEach(viewModel.filteredOrders) { order in
                                    orderCard(order)
                                        .padding(.horizontal, 14)
                                }
                            }

                            Spacer().frame(height: 28)
                        }
                    }
                    .refreshable {
                        await viewModel.loadOrders(forceRefresh: true)
                    }
                }
            }
        }
        .task {
            await viewModel.loadOrders()
        }
        .sheet(isPresented: $showDatePickerSheet) {
            NavigationStack {
                VStack(spacing: 16) {
                    DatePicker(
                        "Select Order Date",
                        selection: $tempDatePickerDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    Spacer()
                }
                .navigationTitle("Filter by Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Clear") {
                            viewModel.selectedDate = nil
                            showDatePickerSheet = false
                        }
                        .foregroundColor(Color(hex: 0xDC2626))
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") {
                            viewModel.selectedDate = tempDatePickerDate
                            showDatePickerSheet = false
                        }
                        .foregroundColor(Color(hex: 0x2563EB))
                        .fontWeight(.bold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // ── 1. ORDERS HEADER CARD (Image 1) ──────────────────────────────
    private var ordersHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Manage Customer Orders")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Spacer()

                // Pill: 42 of 42 Orders
                Text("\(viewModel.filteredOrders.count) of \(viewModel.orders.count) Orders")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(Capsule())
            }

            Text("Item categories & dispatch tracking")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: 0x64748B))

            // 3 Stat Tiles
            HStack(spacing: 8) {
                // 1. Gross Value
                statTile(
                    label: "GROSS VALUE",
                    value: viewModel.grossValueCompact,
                    bgColor: Color(hex: 0xF1F5F9),
                    valueColor: Color(hex: 0x0F172A)
                )

                // 2. Confirmed Orders
                statTile(
                    label: "CONFIRMED",
                    value: "\(viewModel.confirmedCount) Orders",
                    bgColor: Color(hex: 0xEFF6FF),
                    valueColor: Color(hex: 0x2563EB)
                )

                // 3. Approved Orders
                statTile(
                    label: "APPROVED",
                    value: "\(viewModel.approvedCount) Orders",
                    bgColor: Color(hex: 0xECFDF5),
                    valueColor: Color(hex: 0x059669)
                )
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    private func statTile(label: String, value: String, bgColor: Color, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: 0x64748B))
                .tracking(0.4)

            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // ── 2. SEARCH FIELD (Image 1) ────────────────────────────────────
    private var ordersSearchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0x94A3B8))

            TextField("Search by order #, customer name, SK...", text: $viewModel.searchQuery)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: 0x0F172A))
                .autocorrectionDisabled()

            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: 0x94A3B8))
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 3. FILTER ROW (Image 1, 2, 3) ────────────────────────────────
    private var ordersFilterRow: some View {
        HStack(spacing: 6) {
            // 1. Date Chip
            Button {
                tempDatePickerDate = viewModel.selectedDate ?? Date()
                showDatePickerSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundColor(viewModel.selectedDate != nil ? Color(hex: 0x2563EB) : Color(hex: 0x64748B))

                    Text(viewModel.selectedDateDisplay)
                        .font(.system(size: 11, weight: viewModel.selectedDate != nil ? .semibold : .regular))
                        .foregroundColor(viewModel.selectedDate != nil ? Color(hex: 0x2563EB) : Color(hex: 0x64748B))
                        .lineLimit(1)

                    if viewModel.selectedDate != nil {
                        Button {
                            viewModel.selectedDate = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: 0x2563EB))
                        }
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: 0x94A3B8))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .padding(.horizontal, 8)
                .background(viewModel.selectedDate != nil ? Color(hex: 0xEFF6FF) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(viewModel.selectedDate != nil ? Color(hex: 0x2563EB) : Color(hex: 0xE2E8F0), lineWidth: 1)
                )
            }

            // 2. Category Dropdown (Image 2)
            Menu {
                ForEach(viewModel.categories, id: \.self) { cat in
                    Button {
                        viewModel.selectedCategory = cat
                    } label: {
                        HStack {
                            Text(cat)
                            if viewModel.selectedCategory == cat {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text("#")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0x64748B))

                    Text(viewModel.selectedCategory == "All Categories" ? "All Categor..." : viewModel.selectedCategory)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: 0x0F172A))
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: 0x94A3B8))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .padding(.horizontal, 8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
            }

            // 3. Status Dropdown (Image 3)
            Menu {
                ForEach(OrderFilterStatus.allCases, id: \.self) { st in
                    let count = viewModel.statusCount(for: st)
                    Button {
                        viewModel.selectedStatus = st
                    } label: {
                        HStack {
                            Text("\(st.rawValue) (\(count))")
                            if viewModel.selectedStatus == st {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x7C3AED))

                    Text("\(viewModel.selectedStatus.rawValue) (\(viewModel.currentStatusCount))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: 0x0F172A))
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: 0x94A3B8))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .padding(.horizontal, 8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
            }
        }
    }

    // ── 4. ORDER CARD (Image 1) ──────────────────────────────────────
    private func orderCard(_ order: OrderModel) -> some View {
        Button {
            onSelectOrder?(order)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Row 1: Initials Avatar · Customer Name · Date • City · Chevron
                HStack(alignment: .center, spacing: 12) {
                    // Avatar (blue circle with initials)
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0x2563EB))
                            .frame(width: 48, height: 48)

                        Text(initials(order.displayCustomerName))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(order.displayCustomerName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)

                        Text("\(formatDate(order.effectiveDate))  •  \(order.displayCity)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: 0x64748B))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: 0x94A3B8))
                }

                // Divider
                Rectangle()
                    .fill(Color(hex: 0xE2E8F0))
                    .frame(height: 1)

                // Row 2: Order # Pill · Status Pill
                HStack {
                    // Order # Pill
                    Text(order.displayOrderNumber)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: 0x2563EB))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: 0xEFF6FF))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Spacer()

                    // Status Pill
                    statusPill(order.displayStatus)
                }

                // Row 3: Items · Ref · Amount Container
                HStack(alignment: .center) {
                    HStack(spacing: 4) {
                        Text("\(order.displayItemCount) Item\(order.displayItemCount == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: 0x0F172A))

                        Text("• Ref: \(order.lrLabel)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: 0x64748B))
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(formatRupees(order.effectiveAmount))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(hex: 0xF8FAFC))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func statusPill(_ status: String) -> some View {
        let (bg, fg) = statusColors(status)
        return HStack(spacing: 6) {
            Circle()
                .fill(fg)
                .frame(width: 7, height: 7)

            Text(status)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(fg)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(bg)
        .clipShape(Capsule())
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

    private func initials(_ name: String) -> String {
        let words = name.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.isEmpty { return "CU" }
        if words.count == 1 {
            return String(words[0].prefix(2)).uppercased()
        }
        return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
    }

    private func formatDate(_ dateStr: String) -> String {
        if dateStr.isEmpty { return "Recent" }
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        if let d = inFmt.date(from: String(dateStr.prefix(10))) {
            let outFmt = DateFormatter()
            outFmt.dateFormat = "yyyy-MM-dd"
            return outFmt.string(from: d)
        }
        return String(dateStr.prefix(10))
    }

    private func formatRupees(_ amount: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "en_IN")
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        let s = nf.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "₹\(s)"
    }

    private var ordersLoadingSkeleton: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .frame(height: 140)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            }
        }
        .padding(14)
    }

    private var emptyOrdersState: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: 0xEFF6FF))
                    .frame(width: 55, height: 55)

                Image(systemName: "shippingbox")
                    .font(.system(size: 26))
                    .foregroundColor(Color(hex: 0x2563EB))
            }

            Text("No Orders Found")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))

            Text("No customer orders match the current filter criteria.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0x64748B))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
