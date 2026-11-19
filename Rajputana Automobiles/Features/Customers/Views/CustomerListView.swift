import SwiftUI

public struct CustomerListView: View {
    @State private var viewModel = CustomerViewModel()
    public var onSelectCustomer: ((String) -> Void)? = nil
    public var onSelectStatement: ((String) -> Void)? = nil

    @State private var showFilterSheet: Bool = false
    @State private var filterInitialSection: FilterSection = .sort
    @State private var editingCustomer: Customer? = nil
    @State private var customerToDelete: Customer? = nil
    @State private var showDeleteAlert: Bool = false

    public init(
        onSelectCustomer: ((String) -> Void)? = nil,
        onSelectStatement: ((String) -> Void)? = nil
    ) {
        self.onSelectCustomer = onSelectCustomer
        self.onSelectStatement = onSelectStatement
        if let secArg = ProcessInfo.processInfo.arguments.first(where: { $0.starts(with: "-filterSection:") }) {
            let s = secArg.replacingOccurrences(of: "-filterSection:", with: "").lowercased()
            if s == "status" { _filterInitialSection = State(initialValue: .status) }
            else if s == "balance" { _filterInitialSection = State(initialValue: .balance) }
            else if s == "groups" { _filterInitialSection = State(initialValue: .groups) }
            else if s == "cities" { _filterInitialSection = State(initialValue: .cities) }
        }
    }

    public var body: some View {
        ZStack {
            Color(hex: 0xF8FAFC).ignoresSafeArea()

            if viewModel.isLoading && viewModel.customers.isEmpty {
                loadingSkeleton
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // ── 1. Customer & Dealer Management Header Card ─
                        managementHeaderCard
                            .padding(.horizontal, 14)
                            .padding(.top, 12)
                            .padding(.bottom, 12)

                        // ── 2. Search & Filters Bar ────────────────────
                        searchAndFiltersBar
                            .padding(.horizontal, 14)
                            .padding(.bottom, 14)

                        // ── 3. Customer Cards List ─────────────────────
                        if viewModel.filteredCustomers.isEmpty {
                            emptyStateView
                                .padding(.top, 40)
                        } else {
                            ForEach(viewModel.pagedCustomers) { customer in
                                DealerCard(
                                    customer: customer,
                                    onCardClick: {
                                        onSelectCustomer?(customer.id)
                                    },
                                    onEditClick: {
                                        editingCustomer = customer
                                    },
                                    onStatementClick: {
                                        let party = customer.tallyLedgerName?.isEmpty == false ? (customer.tallyLedgerName ?? customer.name) : customer.name
                                        onSelectStatement?(party)
                                    },
                                    onDeleteClick: {
                                        customerToDelete = customer
                                        showDeleteAlert = true
                                    }
                                )
                                .padding(.horizontal, 14)
                                .padding(.bottom, 10)
                                .onAppear {
                                    if customer.id == viewModel.pagedCustomers.last?.id {
                                        viewModel.loadMore()
                                    }
                                }
                            }

                            if viewModel.visibleCount < viewModel.filteredCustomers.count {
                                ProgressView()
                                    .padding(.vertical, 16)
                            }
                        }

                        Spacer().frame(height: 24)
                    }
                }
                .refreshable {
                    await viewModel.refreshCustomers()
                }
            }
        }
        .task {
            if let secArg = ProcessInfo.processInfo.arguments.first(where: { $0.starts(with: "-filterSection:") }) {
                let s = secArg.replacingOccurrences(of: "-filterSection:", with: "").lowercased()
                if s == "status" { filterInitialSection = .status }
                else if s == "balance" { filterInitialSection = .balance }
                else if s == "groups" { filterInitialSection = .groups }
                else if s == "cities" { filterInitialSection = .cities }
            }
            if ProcessInfo.processInfo.arguments.contains("-sheet:filters") {
                showFilterSheet = true
            }
            if viewModel.customers.isEmpty {
                await viewModel.loadCustomers()
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            CustomerFilterSheet(
                customers: viewModel.customers,
                options: viewModel.filterOptions,
                initial: viewModel.filterState,
                initialSection: filterInitialSection,
                onApply: { newState in
                    viewModel.filterState = newState
                    viewModel.resetPaging()
                },
                onDismiss: {
                    showFilterSheet = false
                }
            )
            .presentationDetents([.fraction(0.75)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingCustomer) { customer in
            let detail = CustomerDetailModel(
                _id: customer._id,
                id: customer.customerId ?? customer.id,
                code: customer.code,
                name: customer.name,
                tallyLedgerName: customer.tallyLedgerName,
                address: customer.address,
                city: customer.city,
                state: customer.state,
                country: customer.country,
                pincode: customer.pincode,
                phone: customer.phone,
                email: customer.email,
                gstin: customer.gstin,
                creditLimit: customer.creditLimit,
                paymentTerms: customer.paymentTerms,
                outstandingBalance: customer.outstandingBalance,
                balanceType: customer.balanceType,
                status: customer.status,
                priceTier: nil,
                avatarUrl: customer.avatarUrl,
                avatar: nil
            )
            EditCustomerSheet(customer: detail) { updated in
                Task {
                    await viewModel.refreshCustomers()
                }
            }
        }
        .alert("Delete Customer", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                customerToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let target = customerToDelete {
                    Task {
                        try? await viewModel.deleteCustomer(id: target.id)
                        customerToDelete = nil
                    }
                }
            }
        } message: {
            if let target = customerToDelete {
                Text("Are you sure you want to delete \(target.name)? This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this customer?")
            }
        }
    }

    // ── 1. MANAGEMENT HEADER CARD (Screenshot 1) ─────────────────
    private var managementHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: 0xEEF2FF))
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.2")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(hex: 0x2563EB))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Customer & Dealer Management")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))

                    Text("Real-time ledger accounts, partner profiles, and credit standing synced with TallyPrime.")
                        .font(.system(size: 13, weight: .regular))
                        .lineSpacing(2)
                        .foregroundColor(Color(hex: 0x64748B))
                }
            }

            Divider()
                .background(Color(hex: 0xE2E8F0))

            // 2x2 Metric Tiles
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    metricTile(
                        label: "TOTAL CUSTOMERS",
                        value: "\(viewModel.totalCustomers)",
                        valueColor: Color(hex: 0x0F172A),
                        footerText: "accounts",
                        footerColor: Color(hex: 0x64748B),
                        containerColor: Color(hex: 0xF8FAFC),
                        borderColor: Color(hex: 0xE2E8F0)
                    )

                    metricTile(
                        label: "ACTIVE VERIFIED",
                        value: "\(viewModel.activeVerified)",
                        valueColor: Color(hex: 0x059669),
                        footerText: "good standing",
                        footerColor: Color(hex: 0x059669),
                        containerColor: Color(hex: 0xECFDF5),
                        borderColor: Color(hex: 0xA7F3D0)
                    )
                }

                HStack(spacing: 8) {
                    metricTile(
                        label: "CREDIT LIMIT BREACHES",
                        value: "\(viewModel.creditLimitBreaches)",
                        valueColor: Color(hex: 0xD97706),
                        footerText: "require approval",
                        footerColor: Color(hex: 0xD97706),
                        containerColor: Color(hex: 0xFFFBEB),
                        borderColor: Color(hex: 0xFDE68A)
                    )

                    metricTile(
                        label: "TOTAL OUTSTANDING",
                        value: viewModel.formattedTotalOutstanding,
                        valueColor: Color(hex: 0x2563EB),
                        footerText: "receivable",
                        footerColor: Color(hex: 0x2563EB),
                        containerColor: Color(hex: 0xEFF6FF),
                        borderColor: Color(hex: 0xBFDBFE)
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }

    private func metricTile(
        label: String,
        value: String,
        valueColor: Color,
        footerText: String,
        footerColor: Color,
        containerColor: Color,
        borderColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(Color(hex: 0x64748B))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 6) {
                Circle()
                    .fill(footerColor)
                    .frame(width: 6, height: 6)

                Text(footerText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(footerColor)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(containerColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))
    }

    // ── 2. SEARCH & FILTERS BAR (Screenshot 1) ───────────────────
    private var searchAndFiltersBar: some View {
        HStack(spacing: 10) {
            // Search Input
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: 0x94A3B8))

                TextField("Search customers, GSTIN, city…", text: $viewModel.searchQuery)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .autocorrectionDisabled()

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: 0x94A3B8))
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 45)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)

            // Filters Button
            Button {
                showFilterSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .bold))

                    Text("Filters")
                        .font(.system(size: 14, weight: .bold))

                    if viewModel.filterState.activeCount > 0 {
                        Text("\(viewModel.filterState.activeCount)")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(Color(hex: 0x0B4FC8))
                            .frame(width: 18, height: 18)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 45)
                .background(Color(hex: 0x0B4FC8))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    // ── EMPTY STATE VIEW ─────────────────────────────────────────
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: 0x94A3B8))

            Text("No customers found")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: 0x64748B))

            if !viewModel.filterState.isDefault || !viewModel.searchQuery.isEmpty {
                Button("Reset All Filters") {
                    viewModel.searchQuery = ""
                    viewModel.filterState = CustomerFilterState()
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: 0x2563EB))
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // ── LOADING SKELETON ─────────────────────────────────────────
    private var loadingSkeleton: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.6))
                .frame(height: 220)

            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.6))
                .frame(height: 45)

            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.6))
                    .frame(height: 180)
            }
        }
        .padding(14)
    }
}
