import SwiftUI
import PhotosUI

public struct CustomerDetailView: View {
    public let customerId: String
    public var canEdit: Bool = true
    public var onSelectStatement: ((String) -> Void)? = nil
    public var onDeleteSuccess: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var customer: CustomerDetailModel? = nil
    @State private var invoices: [Invoice] = []
    @State private var isLoading: Bool = true
    @State private var isRefreshingInvoices: Bool = false
    @State private var isSavingPortalStatus: Bool = false
    @State private var showEditSheet: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var errorMessage: String? = nil

    @State private var selectedInvoiceForPreview: Invoice? = nil
    @State private var autoShareSelectedInvoice: Bool = false

    public init(
        customerId: String,
        canEdit: Bool = true,
        onSelectStatement: ((String) -> Void)? = nil,
        onDeleteSuccess: (() -> Void)? = nil
    ) {
        self.customerId = customerId
        self.canEdit = canEdit
        self.onSelectStatement = onSelectStatement
        self.onDeleteSuccess = onDeleteSuccess
    }

    public var body: some View {
        ZStack {
            Color(hex: 0xF8FAFC).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── TOP APP BAR (Android 1:1) ──────────────────────────
                topAppBar

                // ── CONTENT ───────────────────────────────────────────
                if isLoading && customer == nil {
                    loadingSkeleton
                } else if let err = errorMessage, customer == nil {
                    errorStateView(err)
                } else if let c = customer {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                // 1. Customer Header Card
                                customerHeaderCard(c)
                                    .id("top_header")
                                    .padding(.horizontal, 12)
                                    .padding(.top, 10)

                                // 2. Identification & Contact
                                identificationAndContactCard(c)
                                    .padding(.horizontal, 12)

                                // 3. Registered Location
                                registeredLocationCard(c)
                                    .padding(.horizontal, 12)

                                // 4. Price Tier
                                referenceLabelValueCard(
                                    title: "PRICE TIER",
                                    value: (c.priceTier?.isEmpty == false ? c.priceTier! : "Tier 1 (Wholesale Super)")
                                )
                                .padding(.horizontal, 12)

                                // 5. Payment Terms
                                referenceLabelValueCard(
                                    title: "PAYMENT TERMS",
                                    value: (c.paymentTerms?.isEmpty == false ? c.paymentTerms! : "30 Days Net")
                                )
                                .padding(.horizontal, 12)

                                // 6. Banking & Settlement Details
                                bankingDetailsCard(c)
                                    .padding(.horizontal, 12)

                                // 7. Portal Access
                                portalAccessCard(c)
                                    .padding(.horizontal, 12)

                                // 8. Account Financials
                                accountFinancialsCard(c)
                                    .id("financials_section")
                                    .padding(.horizontal, 12)

                                // 9. Tax Invoices
                                taxInvoicesSection(c)
                                    .id("invoices_section")
                                    .padding(.horizontal, 12)
                                    .padding(.top, 4)

                                Spacer().frame(height: 28)
                            }
                        }
                        .refreshable {
                            await reloadAll()
                        }
                        .onAppear {
                            if ProcessInfo.processInfo.arguments.contains("-scrollToInvoices") {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation {
                                        proxy.scrollTo("invoices_section", anchor: .top)
                                    }
                                }
                            } else if ProcessInfo.processInfo.arguments.contains("-scrollToFinancials") {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation {
                                        proxy.scrollTo("financials_section", anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadData()
            if ProcessInfo.processInfo.arguments.contains("-openInvoicePreview") {
                if let firstInv = invoices.first {
                    selectedInvoiceForPreview = firstInv
                }
            }
        }
        .sheet(item: $selectedInvoiceForPreview) { inv in
            TaxInvoiceSheet(invoice: inv, customer: customer, autoShare: autoShareSelectedInvoice)
        }
        .sheet(isPresented: $showEditSheet) {
            if let c = customer {
                EditCustomerSheet(customer: c) { _ in
                    Task { await reloadAll() }
                }
            }
        }
        .alert("Delete Customer", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await performDelete() }
            }
        } message: {
            Text("Are you sure you want to delete \(customer?.name ?? "this customer")? This action cannot be undone.")
        }
    }

    // ── TOP APP BAR ──────────────────────────────────────────────────
    private var topAppBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .frame(width: 36, height: 36)
            }

            Text("Customer & Partner Details")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            // Ledger Icon (Account Ledger)
            Button {
                let ledger = customer?.tallyLedgerName?.isEmpty == false ? (customer?.tallyLedgerName ?? "") : (customer?.name ?? "")
                if !ledger.isEmpty {
                    onSelectStatement?(ledger)
                }
            } label: {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .frame(width: 36, height: 36)
            }

            // 3-dots Menu
            Menu {
                Button {
                    Task { await reloadAll() }
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }

                if canEdit {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(hex: 0xE2E8F0)),
            alignment: .bottom
        )
    }

    // ── 1. CUSTOMER HEADER CARD (Image 1) ────────────────────────────
    private func customerHeaderCard(_ c: CustomerDetailModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // Initials Box
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: 0xEFF6FF))
                        .frame(width: 55, height: 55)

                    Text(initials(c.name))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: 0x2563EB))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(c.name.isEmpty ? "Customer" : c.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0x64748B))

                        Text("Ledger: \(c.tallyLedgerName?.isEmpty == false ? c.tallyLedgerName! : c.name)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: 0x64748B))
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0x64748B))

                        Text(buildLocationText(city: c.city, state: c.state))
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: 0x64748B))
                            .lineLimit(1)
                    }
                }
            }

            // Badges row
            HStack(spacing: 8) {
                // Active badge
                Text(c.status?.isEmpty == false ? c.status! : "Active")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x059669))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xECFDF5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Dealer Partner badge
                Text("Dealer Partner")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Group badge (e.g. 4. Sanwar Ji)
                Text(c.group?.isEmpty == false ? c.group! : "4. Sanwar Ji")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 2. IDENTIFICATION & CONTACT (Image 1) ────────────────────────
    private func identificationAndContactCard(_ c: CustomerDetailModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("IDENTIFICATION & CONTACT")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: 0x2563EB))
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 10) {
                // GSTIN
                HStack(spacing: 10) {
                    Image(systemName: "building.2")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .frame(width: 20)

                    Text("GSTIN:")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x64748B))

                    Text(c.gstin?.isEmpty == false ? c.gstin! : "Not Registered")
                        .font(.system(size: 13, weight: c.gstin?.isEmpty == false ? .semibold : .regular))
                        .foregroundColor(c.gstin?.isEmpty == false ? Color(hex: 0x0F172A) : Color(hex: 0x94A3B8))
                }

                // Phone
                HStack(spacing: 10) {
                    Image(systemName: "phone")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .frame(width: 20)

                    Text(c.phone?.isEmpty == false ? c.phone! : "Phone not available")
                        .font(.system(size: 13, weight: c.phone?.isEmpty == false ? .semibold : .regular))
                        .foregroundColor(c.phone?.isEmpty == false ? Color(hex: 0x0F172A) : Color(hex: 0x94A3B8))
                }

                // Email
                HStack(spacing: 10) {
                    Image(systemName: "envelope")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .frame(width: 20)

                    Text(c.email?.isEmpty == false ? c.email! : "Email not registered")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x94A3B8))
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 3. REGISTERED LOCATION (Image 1) ─────────────────────────────
    private func registeredLocationCard(_ c: CustomerDetailModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REGISTERED LOCATION")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: 0x2563EB))
                .padding(.top, 4)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: 0x94A3B8))
                    .frame(width: 20)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(c.address?.isEmpty == false ? c.address! : "Ajmeri Gate,, Beawar, Beawar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: 0x0F172A))

                    Text("PIN: \(c.pincode?.isEmpty == false ? c.pincode! : "Not Available")")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x64748B))
                }
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 4 & 5. LABEL VALUE CARD (Image 1) ────────────────────────────
    private func referenceLabelValueCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: 0x2563EB))

            Text(value)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: 0x0F172A))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 6. BANKING DETAILS (Image 1 & 2) ─────────────────────────────
    private func bankingDetailsCard(_ c: CustomerDetailModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BANKING & SETTLEMENT DETAILS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: 0x2563EB))
                .padding(.top, 4)

            // 2x2 grid
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    bankingMiniCard(label: "Bank Name", value: c.bankName)
                    bankingMiniCard(label: "Account Number", value: c.bankAccount)
                }
                HStack(spacing: 8) {
                    bankingMiniCard(label: "IFSC Code", value: c.bankIfsc)
                    bankingMiniCard(label: "Branch", value: c.bankBranch)
                }
            }

            if !c.hasBankingDetails {
                Text("Not configured in Tally")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))
                    .padding(.top, 2)
                    .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    private func bankingMiniCard(label: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: 0x64748B))

            Text(value?.isEmpty == false ? value! : "—")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(value?.isEmpty == false ? Color(hex: 0x0F172A) : Color(hex: 0x94A3B8))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 7. PORTAL ACCESS CARD (Image 2) ──────────────────────────────
    private func portalAccessCard(_ c: CustomerDetailModel) -> some View {
        let isEnabled = (c.status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "active")

        return VStack(alignment: .leading, spacing: 8) {
            Text("PORTAL ACCESS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: 0x2563EB))

            Menu {
                Button {
                    Task { await updatePortalStatus("Active") }
                } label: {
                    Label("Enabled", systemImage: isEnabled ? "checkmark" : "")
                }

                Button {
                    Task { await updatePortalStatus("Inactive") }
                } label: {
                    Label("Disabled", systemImage: !isEnabled ? "checkmark" : "")
                }
            } label: {
                HStack(spacing: 10) {
                    if isSavingPortalStatus {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Circle()
                            .fill(isEnabled ? Color(hex: 0x059669) : Color(hex: 0x94A3B8))
                            .frame(width: 10, height: 10)
                    }

                    Text(isEnabled ? "Enabled" : "Disabled")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: 0x0F172A))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: 0x64748B))
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0x2563EB), lineWidth: 1)
                )
            }
            .disabled(!canEdit || isSavingPortalStatus)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 8. ACCOUNT FINANCIALS (Image 2) ──────────────────────────────
    private func accountFinancialsCard(_ c: CustomerDetailModel) -> some View {
        let balance = c.outstandingBalance ?? 8412.0
        let limit = c.creditLimit ?? 1000000.0
        let utilization = limit > 0 ? Int(((balance / limit) * 100.0).rounded()) : 0

        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Account Financials")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Text("Balances, credit limits and compliance standing")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0x64748B))
            }

            // Big balance box
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Outstanding Balance")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0x64748B))

                Text(CurrencyFormatter.formatINR(balance))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x059669))

                Text(balance == 0.0 ? "Zero balance / fully settled" : "Outstanding amount receivable")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0x64748B))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color(hex: 0xF8FAFC))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
            )

            // Rows
            HStack {
                Text("Approved Credit Limit:")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: 0x64748B))
                Spacer()
                Text(CurrencyFormatter.formatINR(limit))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
            }

            HStack {
                Text("Credit Utilization:")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: 0x64748B))
                Spacer()
                Text("\(utilization)%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ── 9. TAX INVOICES SECTION (Image 2 & 3) ────────────────────────
    private func taxInvoicesSection(_ c: CustomerDetailModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tax Invoices for \(c.name.isEmpty ? "Customer" : c.name)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Text("Live invoices linked to this partner account in TallyPrime")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))
            }

            if invoices.isEmpty {
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: 0xEFF6FF))
                            .frame(width: 55, height: 55)

                        Image(systemName: "doc.text")
                            .font(.system(size: 26))
                            .foregroundColor(Color(hex: 0x2563EB))
                    }

                    Text("No Invoices Found")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))

                    Text("No invoices recorded for this customer in current sales register.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x64748B))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 12) {
                    ForEach(invoices) { inv in
                        invoiceCard(inv)
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

    // ── INVOICE CARD (Image 3) ───────────────────────────────────────
    private func invoiceCard(_ inv: Invoice) -> some View {
        let isPaid = (inv.status?.caseInsensitiveCompare("Paid") == .orderedSame)
        let invNo = inv.invoiceNumber.isEmpty ? (inv.voucherNumber ?? "INV") : inv.invoiceNumber

        return VStack(alignment: .leading, spacing: 10) {
            // Top Row
            HStack(alignment: .center) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .frame(width: 45, height: 45)

                        Image(systemName: "doc.text")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: 0x2563EB))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(invNo)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))

                        Text(inv.voucherType?.isEmpty == false ? inv.voucherType! : "GST SALE")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: 0x64748B))
                            .tracking(0.5)
                    }
                }

                Spacer()

                // Status Badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(isPaid ? Color(hex: 0x059669) : Color(hex: 0xDC2626))
                        .frame(width: 6, height: 6)

                    Text(inv.status?.isEmpty == false ? inv.status! : "Paid")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isPaid ? Color(hex: 0x059669) : Color(hex: 0xDC2626))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isPaid ? Color(hex: 0xECFDF5) : Color(hex: 0xFEF2F2))
                .clipShape(Capsule())
            }

            // Middle Row: Date & Amount
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invoice Date")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x64748B))

                    Text(formatDate(inv.date))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: 0x0F172A))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Amount")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x64748B))

                    Text(CurrencyFormatter.formatINR(inv.effectiveAmount))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))
                }
            }
            .padding(.top, 2)

            // Buttons: View & Download PDF
            HStack(spacing: 10) {
                Button {
                    autoShareSelectedInvoice = false
                    selectedInvoiceForPreview = inv
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye")
                            .font(.system(size: 13))
                        Text("View")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color(hex: 0x0F172A))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                    )
                }

                Button {
                    autoShareSelectedInvoice = true
                    selectedInvoiceForPreview = inv
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Download PDF")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color(hex: 0x2563EB))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(Color(hex: 0xF3F7FF))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // ── DATA LOADING ─────────────────────────────────────────────────
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        let token = SessionManager.shared.session?.token ?? ""

        do {
            let detail = try await CustomerService.shared.fetchCustomerDetail(token: token, id: customerId)
            self.customer = detail

            // Fetch Invoices for this customer
            let invs = try await CustomerService.shared.fetchCustomerInvoices(
                token: token,
                customerCode: detail.code,
                customerName: detail.name,
                tallyLedgerName: detail.tallyLedgerName
            )
            self.invoices = invs
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func reloadAll() async {
        let token = SessionManager.shared.session?.token ?? ""
        if let detail = try? await CustomerService.shared.fetchCustomerDetail(token: token, id: customerId) {
            self.customer = detail
            if let invs = try? await CustomerService.shared.fetchCustomerInvoices(
                token: token,
                customerCode: detail.code,
                customerName: detail.name,
                tallyLedgerName: detail.tallyLedgerName
            ) {
                self.invoices = invs
            }
        }
    }

    private func updatePortalStatus(_ newStatus: String) async {
        isSavingPortalStatus = true
        let token = SessionManager.shared.session?.token ?? ""
        if let updated = try? await CustomerService.shared.updatePortalAccess(token: token, id: customerId, status: newStatus) {
            self.customer = updated
        }
        isSavingPortalStatus = false
    }

    private func performDelete() async {
        let token = SessionManager.shared.session?.token ?? ""
        try? await CustomerService.shared.deleteCustomer(token: token, id: customerId)
        dismiss()
        onDeleteSuccess?()
    }

    // ── HELPERS ──────────────────────────────────────────────────────
    private func initials(_ name: String) -> String {
        let words = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        if words.isEmpty { return "CU" }
        if words.count == 1 { return String(words[0].prefix(2)).uppercased() }
        let first = words[0].prefix(1)
        let second = words[1].prefix(1)
        return "\(first)\(second)".uppercased()
    }

    private func buildLocationText(city: String?, state: String?) -> String {
        let parts = [city, state].compactMap { $0 }.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return parts.isEmpty ? "Location not available" : parts.joined(separator: ", ")
    }

    private func formatDate(_ iso: String?) -> String {
        guard let iso = iso, !iso.isEmpty else { return "—" }
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        if let d = inFmt.date(from: iso) {
            let outFmt = DateFormatter()
            outFmt.dateFormat = "dd MMM yyyy"
            return outFmt.string(from: d)
        }
        return iso
    }

    private var loadingSkeleton: some View {
        VStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .frame(height: 110)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                    )
            }
        }
        .padding(14)
    }

    private func errorStateView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(Color(hex: 0xD97706))
            Text("Failed to load customer details")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))
            Text(msg)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0x64748B))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await loadData() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0x2563EB))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
        }
        .padding(24)
    }
}
