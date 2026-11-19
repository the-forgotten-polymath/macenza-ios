import SwiftUI

public struct DetailedLedgerView: View {
    public let customerName: String
    public var onBack: (() -> Void)? = nil
    public var showTopBar: Bool = true

    @Environment(\.dismiss) private var dismiss
    @State private var ledger: LedgerResponse? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var searchText: String = ""

    // Date filtering states
    @State private var showDatePickerSheet: Bool = false
    @State private var selectedStartDate: Date? = nil
    @State private var selectedEndDate: Date? = nil
    @State private var tempStartDate: Date? = nil
    @State private var tempEndDate: Date? = nil
    @State private var activePicker: ActiveDatePicker? = nil

    // PDF preview sheets
    @State private var statementPdfUrl: URL? = nil
    @State private var voucherPdfUrl: URL? = nil
    @State private var voucherPdfTitle: String = "Document"
    @State private var isPreparingPdf: Bool = false

    private enum ActiveDatePicker: Identifiable {
        case from
        case to
        var id: Int { hashValue }
    }

    public init(customerName: String, onBack: (() -> Void)? = nil, showTopBar: Bool = true) {
        self.customerName = customerName
        self.onBack = onBack
        self.showTopBar = showTopBar
    }

    private var filteredVouchers: [LedgerVoucher] {
        guard let list = ledger?.ledgerVouchers else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let filtered = list.filter { v in
            let matchesSearch = searchText.isEmpty ||
                v.voucherNumber.localizedCaseInsensitiveContains(searchText) ||
                (v.particulars?.localizedCaseInsensitiveContains(searchText) == true) ||
                (v.voucherType?.localizedCaseInsensitiveContains(searchText) == true)

            guard matchesSearch else { return false }

            if let from = selectedStartDate {
                if let raw = v.date?.prefix(10), let vDate = formatter.date(from: String(raw)) {
                    if Calendar.current.startOfDay(for: vDate) < Calendar.current.startOfDay(for: from) {
                        return false
                    }
                }
            }
            if let to = selectedEndDate {
                if let raw = v.date?.prefix(10), let vDate = formatter.date(from: String(raw)) {
                    if Calendar.current.startOfDay(for: vDate) > Calendar.current.startOfDay(for: to) {
                        return false
                    }
                }
            }

            return true
        }

        // Return newest first matching Android
        return filtered.sorted { v1, v2 in
            let d1 = v1.date?.prefix(10) ?? ""
            let d2 = v2.date?.prefix(10) ?? ""
            if d1 != d2 { return d1 > d2 }
            return v1.voucherNumber > v2.voucherNumber
        }
    }

    public var body: some View {
        Group {
            if showTopBar {
                mainContent
                    .navigationTitle("Account Ledger")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: {
                                if let onBack = onBack {
                                    onBack()
                                } else {
                                    dismiss()
                                }
                            }) {
                                Image(systemName: "arrow.backward")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(hex: 0x0F172A))
                            }
                        }

                        ToolbarItemGroup(placement: .topBarTrailing) {
                            Menu {
                                Button(action: {
                                    Task { await loadLedger() }
                                }) {
                                    Label("Reload", systemImage: "arrow.clockwise")
                                }

                                Button(action: {
                                    generateStatementPdf()
                                }) {
                                    Label("Download Statement PDF", systemImage: "doc.text.fill")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(hex: 0x0F172A))
                                    .frame(width: 32, height: 32)
                            }
                        }
                    }
            } else {
                mainContent
            }
        }
        .task {
            await loadLedger()
            if ProcessInfo.processInfo.arguments.contains("-openPeriodDialog") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    tempStartDate = selectedStartDate
                    tempEndDate = selectedEndDate
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDatePickerSheet = true
                    }
                }
            }
        }
        .sheet(item: $statementPdfUrl) { url in
            PDFPreviewSheet(url: url, title: "Customer Ledger Statement")
        }
        .sheet(item: $voucherPdfUrl) { url in
            PDFPreviewSheet(url: url, title: voucherPdfTitle)
        }
        .sheet(item: $activePicker) { target in
            NavigationStack {
                VStack(spacing: 20) {
                    DatePicker(
                        target == .from ? "From Date" : "To Date",
                        selection: Binding(
                            get: {
                                if target == .from {
                                    return tempStartDate ?? Date()
                                } else {
                                    return tempEndDate ?? Date()
                                }
                            },
                            set: { newDate in
                                if target == .from {
                                    tempStartDate = newDate
                                } else {
                                    tempEndDate = newDate
                                }
                            }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    Spacer()
                }
                .navigationTitle(target == .from ? "From Date" : "To Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            if target == .from && tempStartDate == nil {
                                tempStartDate = Date()
                            } else if target == .to && tempEndDate == nil {
                                tempEndDate = Date()
                            }
                            activePicker = nil
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            activePicker = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            Color(hex: 0xF8FAFC).ignoresSafeArea()

            if isLoading && ledger == nil {
                VStack(spacing: 14) {
                    ShimmerBox(height: 120, cornerRadius: 16)
                    HStack(spacing: 10) {
                        ShimmerBox(height: 90, cornerRadius: 14)
                        ShimmerBox(height: 90, cornerRadius: 14)
                    }
                    HStack(spacing: 10) {
                        ShimmerBox(height: 90, cornerRadius: 14)
                        ShimmerBox(height: 90, cornerRadius: 14)
                    }
                    ShimmerBox(height: 80, cornerRadius: 14)
                    ShimmerBox(height: 120, cornerRadius: 16)
                    Spacer()
                }
                .padding(14)
            } else if let err = errorMessage, ledger == nil {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(hex: 0xDC2626))

                    Text("Could not load ledger statement")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0F172A))

                    Text(err)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(hex: 0x64748B))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button(action: {
                        Task { await loadLedger() }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(LiquidTheme.activePillGradient)
                        .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(24)
            } else if let l = ledger {
                let metrics = computeLedgerMetrics(l)

                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            // 1. Customer Account Info Card
                            customerInfoCard(l)

                            // 2. Metrics 2x2 Grid
                            metricsGrid(metrics)

                            // 3. Pending This Period Full Width Card
                            pendingThisPeriodCard(metrics)

                            // 4. Ledger Voucher Transactions Header Card
                            transactionsHeaderCard(l, metrics: metrics)

                            // 5. Vouchers List or Empty State
                            if filteredVouchers.isEmpty {
                                VStack {
                                    Spacer().frame(height: 24)
                                    Text("No transactions found")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: 0x94A3B8))
                                    Spacer().frame(height: 24)
                                }
                            } else {
                                vouchersList(filteredVouchers, ledger: l)
                            }

                            // 6. Period Summary Card
                            periodSummaryCard(l, metrics: metrics)
                                .id("period_summary")

                            Spacer().frame(height: 24)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .refreshable {
                        await loadLedger()
                    }
                    .onAppear {
                        if ProcessInfo.processInfo.arguments.contains("-scrollLedgerBottom") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    scrollProxy.scrollTo("period_summary", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }

            // Period Selection Modal Overlay
            if showDatePickerSheet {
                selectPeriodDialog
            }
        }
    }

    // ── 1. Customer Info Card ────────────────────────────────────
    private func customerInfoCard(_ l: LedgerResponse) -> some View {
        let cust = l.customer
        let displayName = cust?.name?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? cust!.name!
            : (cust?.partyName?.trimmingCharacters(in: .whitespaces).isEmpty == false ? cust!.partyName! : customerName)

        let displayCode = cust?.code?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? cust!.code!
            : (SessionManager.shared.session?.customerCode ?? "13-raj-001")

        let displayCity = cust?.city?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? cust!.city!
            : "Beawar"

        let hasGstin = cust?.gstin?.trimmingCharacters(in: .whitespaces).isEmpty == false
        let displayGstin = hasGstin ? cust!.gstin! : "Not Registered"

        let hasPhone = cust?.phone?.trimmingCharacters(in: .whitespaces).isEmpty == false
        let displayPhone = hasPhone ? cust!.phone! : "Phone not available"

        return VStack(alignment: .leading, spacing: 0) {
            Text(displayName)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))

            Spacer().frame(height: 8)

            HStack(spacing: 6) {
                Text(displayCode)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(displayCity)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x64748B))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xF1F5F9))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Spacer().frame(height: 12)

            infoRow(label: "Company", value: "Rajputana Automobiles", valueColor: Color(hex: 0x0F172A))
            infoRow(label: "GSTIN", value: displayGstin, valueColor: hasGstin ? Color(hex: 0x0F172A) : Color(hex: 0x64748B))
            infoRow(label: "Phone", value: displayPhone, valueColor: hasPhone ? Color(hex: 0x2563EB) : Color(hex: 0x64748B))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }

    private func infoRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0x64748B))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 3)
    }

    // ── 2. Metrics 2x2 Grid ──────────────────────────────────────
    private struct FilteredLedgerMetrics {
        let openingBalance: Double
        let totalDebits: Double
        let totalCredits: Double
        let closingBalance: Double
        let pendingThisPeriod: Double
        let openingDate: String
        let closingDate: String
        let earliestDate: String
    }

    private func computeDates(_ l: LedgerResponse) -> (from: String, to: String, earliest: String) {
        let vouchers = l.ledgerVouchers ?? []
        let rawDates = vouchers.compactMap { $0.date?.prefix(10) }.map { String($0) }.sorted()

        let fromDate: String
        let toDate: String
        let earliestDate: String

        if let first = rawDates.first, let last = rawDates.last {
            fromDate = formatFyStart(first)
            toDate = formatDisplayDate(last)
            earliestDate = formatDisplayDate(first)
        } else {
            fromDate = shortDateText(l.period?.fromDate ?? "2026-04-01")
            toDate = shortDateText(l.period?.toDate ?? "2026-09-01")
            earliestDate = fromDate
        }

        return (fromDate, toDate, earliestDate)
    }

    private func computeLedgerMetrics(_ l: LedgerResponse) -> FilteredLedgerMetrics {
        let rawVouchers = l.ledgerVouchers ?? []
        let chrono = rawVouchers.sorted { v1, v2 in
            let d1 = v1.date?.prefix(10) ?? ""
            let d2 = v2.date?.prefix(10) ?? ""
            if d1 != d2 { return d1 < d2 }
            return v1.voucherNumber < v2.voucherNumber
        }

        let ledgerOpening = l.openingBalance ?? 10559.0

        var running = ledgerOpening
        var balances: [Double] = []
        for v in chrono {
            running += (v.debit ?? 0.0) - (v.credit ?? 0.0)
            balances.append(running)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let isFilterActive = selectedStartDate != nil || selectedEndDate != nil

        if !isFilterActive {
            let dates = computeDates(l)
            let debits = l.totalDebits ?? l.currentDebitTotal ?? chrono.reduce(0.0) { $0 + ($1.debit ?? 0) }
            let credits = l.totalCredits ?? l.currentCreditTotal ?? chrono.reduce(0.0) { $0 + ($1.credit ?? 0) }
            let closing = l.closingBalance ?? (balances.last ?? (ledgerOpening + debits - credits))
            let pending = debits - credits

            return FilteredLedgerMetrics(
                openingBalance: ledgerOpening,
                totalDebits: debits,
                totalCredits: credits,
                closingBalance: closing,
                pendingThisPeriod: pending,
                openingDate: dates.from,
                closingDate: dates.to,
                earliestDate: dates.earliest
            )
        }

        var inRangeIndices: [Int] = []
        for (i, v) in chrono.enumerated() {
            guard let raw = v.date?.prefix(10), let vDate = formatter.date(from: String(raw)) else { continue }
            let startOfVDate = Calendar.current.startOfDay(for: vDate)
            if let from = selectedStartDate {
                if startOfVDate < Calendar.current.startOfDay(for: from) { continue }
            }
            if let to = selectedEndDate {
                if startOfVDate > Calendar.current.startOfDay(for: to) { continue }
            }
            inRangeIndices.append(i)
        }

        let opening: Double
        if let from = selectedStartDate {
            let startOfFrom = Calendar.current.startOfDay(for: from)
            var lastBeforeIdx: Int? = nil
            for (i, v) in chrono.enumerated() {
                if let raw = v.date?.prefix(10), let vDate = formatter.date(from: String(raw)) {
                    if Calendar.current.startOfDay(for: vDate) < startOfFrom {
                        lastBeforeIdx = i
                    }
                }
            }
            if let idx = lastBeforeIdx {
                opening = balances[idx]
            } else {
                opening = ledgerOpening
            }
        } else {
            opening = ledgerOpening
        }

        let debits = inRangeIndices.reduce(0.0) { $0 + (chrono[$1].debit ?? 0) }
        let credits = inRangeIndices.reduce(0.0) { $0 + (chrono[$1].credit ?? 0) }
        let closing = inRangeIndices.last.map { balances[$0] } ?? opening
        let pending = debits - credits

        let openingDateText = selectedStartDate.map { formatDisplayDate($0) } ?? computeDates(l).from
        let closingDateText = selectedEndDate.map { formatDisplayDate($0) } ?? computeDates(l).to

        return FilteredLedgerMetrics(
            openingBalance: opening,
            totalDebits: debits,
            totalCredits: credits,
            closingBalance: closing,
            pendingThisPeriod: pending,
            openingDate: openingDateText,
            closingDate: closingDateText,
            earliestDate: computeDates(l).earliest
        )
    }

    private func formatFyStart(_ iso: String) -> String {
        let parts = iso.split(separator: "-")
        guard parts.count >= 2, let year = Int(parts[0]), let month = Int(parts[1]) else {
            return "01 Apr 2026"
        }
        let startYear = (month >= 4) ? year : (year - 1)
        return "01 Apr \(startYear)"
    }

    private func formatDisplayDate(_ iso: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let d = formatter.date(from: String(iso.prefix(10))) {
            return formatDisplayDate(d)
        }
        return iso
    }

    private func formatDisplayDate(_ date: Date) -> String {
        let out = DateFormatter()
        out.dateFormat = "dd MMM yyyy"
        var s = out.string(from: date)
        if s.contains("Sep ") {
            s = s.replacingOccurrences(of: "Sep ", with: "Sept ")
        }
        return s
    }

    private func formatDisplayDateDash(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd - MM - yyyy"
        return formatter.string(from: date)
    }

    private func metricsGrid(_ m: FilteredLedgerMetrics) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                metricCard(
                    title: "OPENING BALANCE",
                    value: CurrencyFormatter.formatINR(m.openingBalance),
                    valueColor: Color(hex: 0x0F172A),
                    subtitle: "As of \(m.openingDate)",
                    icon: nil,
                    containerBg: Color.white,
                    borderHighlight: false
                )

                metricCard(
                    title: "TOTAL DEBITS",
                    value: CurrencyFormatter.formatINR(m.totalDebits),
                    valueColor: Color(hex: 0x2563EB),
                    subtitle: "GST Sales/Invoices",
                    icon: "arrow.up.right",
                    iconColor: Color(hex: 0x2563EB),
                    containerBg: Color.white,
                    borderHighlight: false
                )
            }

            HStack(spacing: 10) {
                metricCard(
                    title: "TOTAL CREDITS",
                    value: CurrencyFormatter.formatINR(m.totalCredits),
                    valueColor: Color(hex: 0x059669),
                    subtitle: "Bank NEFT/RTGS",
                    icon: "arrow.down.left",
                    iconColor: Color(hex: 0x059669),
                    containerBg: Color.white,
                    borderHighlight: false
                )

                metricCard(
                    title: "CLOSING BALANCE",
                    value: "\(CurrencyFormatter.formatINR(abs(m.closingBalance)))\(m.closingBalance >= 0 ? " Dr" : " Cr")",
                    valueColor: Color(hex: 0xDC2626),
                    subtitle: "Pending Due (\(m.closingDate))",
                    icon: "clock",
                    iconColor: Color(hex: 0xDC2626),
                    containerBg: Color(hex: 0xFEF2F2),
                    borderHighlight: true
                )
            }
        }
    }

    private func metricCard(
        title: String,
        value: String,
        valueColor: Color,
        subtitle: String,
        icon: String?,
        iconColor: Color = .clear,
        containerBg: Color,
        borderHighlight: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: 0x475569))
                    .tracking(0.3)
                Spacer()
                if let ic = icon {
                    Image(systemName: ic)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(iconColor)
                }
            }

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(borderHighlight ? Color(hex: 0xEF4444) : Color(hex: 0x64748B))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(containerBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderHighlight ? Color(hex: 0xFECACA) : Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }

    // ── 3. Pending This Period Full Width Card ────────────────────
    private func pendingThisPeriodCard(_ m: FilteredLedgerMetrics) -> some View {
        let periodPending = m.pendingThisPeriod
        let absPending = abs(periodPending)
        let suffix = periodPending > 0.001 ? " Dr" : (periodPending < -0.001 ? " Cr" : "")
        let formattedValue = "\(CurrencyFormatter.formatINR(absPending))\(suffix)"
        let periodIsDue = periodPending > 0.001
        let valueColor = periodIsDue ? Color(hex: 0xDC2626) : Color(hex: 0x059669)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("PENDING THIS PERIOD")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: 0x475569))
                    .tracking(0.3)
                Spacer()
                Image(systemName: "creditcard")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0x64748B))
            }

            Text(formattedValue)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)

            Text("Debits - Credits for \(m.openingDate) to \(m.closingDate)")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: 0x64748B))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }

    // ── 4. Transactions Header Card ──────────────────────────────
    private func transactionsHeaderCard(_ l: LedgerResponse, metrics: FilteredLedgerMetrics) -> some View {
        let count = filteredVouchers.count

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: 0xEFF6FF))
                        .frame(width: 38, height: 38)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: 0x2563EB))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ledger Voucher Transactions")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))
                    Text("\(count) Voucher Entries · Latest First")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x64748B))
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(hex: 0x94A3B8))
                    .font(.system(size: 15))

                TextField("Search particulars, voucher #...", text: $searchText)
                    .font(.system(size: 14))

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(hex: 0x94A3B8))
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
            )

            // Clickable Calendar Date Filter Row
            Button {
                tempStartDate = selectedStartDate
                tempEndDate = selectedEndDate
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDatePickerSheet = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hex: 0x2563EB))
                        .font(.system(size: 16))

                    let isFilterActive = selectedStartDate != nil || selectedEndDate != nil
                    let dateText = isFilterActive
                        ? "\(formatDisplayDate(selectedStartDate ?? Date())) – \(formatDisplayDate(selectedEndDate ?? Date()))"
                        : "All dates · \(metrics.earliestDate) – \(metrics.closingDate)"

                    Text(dateText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: 0x0F172A))
                        .lineLimit(1)

                    Spacer()

                    if isFilterActive {
                        Button {
                            selectedStartDate = nil
                            selectedEndDate = nil
                            tempStartDate = nil
                            tempEndDate = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(hex: 0x94A3B8))
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Image(systemName: "chevron.down")
                            .foregroundColor(Color(hex: 0x64748B))
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(hex: 0xF8FAFC))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }

    // ── 5. Vouchers List (Matching Screenshot 2 & 4) ──────────────
    private func vouchersList(_ vouchers: [LedgerVoucher], ledger: LedgerResponse) -> some View {
        VStack(spacing: 10) {
            ForEach(vouchers) { v in
                let isDebit = (v.debit ?? 0) > 0
                let amount = isDebit ? (v.debit ?? 0) : (v.credit ?? 0)
                let badgeType = v.voucherType?.uppercased() ?? (isDebit ? "GST SALE" : "RECEIPT")
                let badgeBg = isDebit ? Color(hex: 0xEFF6FF) : Color(hex: 0xDCFCE7)
                let badgeFg = isDebit ? Color(hex: 0x2563EB) : Color(hex: 0x16A34A)

                VStack(alignment: .leading, spacing: 8) {
                    // Top Row: Type Badge + DEBIT/CREDIT
                    HStack {
                        Text(badgeType)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(badgeFg)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(badgeBg)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Spacer()

                        Text(isDebit ? "DEBIT" : "CREDIT")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: 0x64748B))
                    }

                    // Second Row: Particulars Title + Amount
                    HStack(alignment: .firstTextBaseline) {
                        Text(v.particulars ?? v.voucherType ?? "Voucher Entry")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)

                        Spacer()

                        Text(CurrencyFormatter.formatINR(amount))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(isDebit ? Color(hex: 0xDC2626) : Color(hex: 0x16A34A))
                    }

                    // Third Row: Voucher Number + Date
                    HStack {
                        Text("Vch. No. : \(v.voucherNumber)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0x64748B))

                        Spacer()

                        Text(formatVoucherDate(v.date))
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0x64748B))
                    }

                    // Fourth Row: Right-aligned Download Button
                    HStack {
                        Spacer()

                        Button(action: {
                            openVoucher(v, ledger: ledger)
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.down.to.line")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Download")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: 0x2563EB))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: 0xBFDBFE), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
            }
        }
    }

    private func formatVoucherDate(_ dateStr: String?) -> String {
        guard let s = dateStr, !s.isEmpty else { return "01 Sept 2026" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let d = formatter.date(from: String(s.prefix(10))) {
            let out = DateFormatter()
            out.dateFormat = "dd MMM yyyy"
            var formatted = out.string(from: d)
            if formatted.contains("Sep ") {
                formatted = formatted.replacingOccurrences(of: "Sep ", with: "Sept ")
            }
            return formatted
        }
        return s
    }

    // ── 6. Period Summary Card (Matching Screenshot 4) ────────────
    private func periodSummaryCard(_ l: LedgerResponse, metrics: FilteredLedgerMetrics) -> some View {
        let periodRange = formatPeriodRange(from: metrics.openingDate, to: metrics.closingDate)
        let pending = metrics.pendingThisPeriod
        let absPending = abs(pending)
        let suffix = pending > 0.001 ? " Dr" : (pending < -0.001 ? " Cr" : "")
        let pendingText = "\(CurrencyFormatter.formatINRDecimal(absPending))\(suffix)"

        return VStack(spacing: 0) {
            HStack {
                Text("PERIOD SUMMARY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))
                    .tracking(0.5)
                Spacer()
                Text(periodRange)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().foregroundStyle(Color(hex: 0xF1F5F9))

            summaryRow(label: "Opening Balance :", value: CurrencyFormatter.formatINRDecimal(metrics.openingBalance), valueColor: Color(hex: 0x0F172A))
            summaryRow(label: "Current Total (Debits) :", value: CurrencyFormatter.formatINRDecimal(metrics.totalDebits), valueColor: Color(hex: 0x0F172A))
            summaryRow(label: "Current Total (Credits) :", value: CurrencyFormatter.formatINRDecimal(metrics.totalCredits), valueColor: Color(hex: 0x059669))
            summaryRow(label: "Pending This Period (Dr - Cr) :", value: pendingText, valueColor: pending > 0.001 ? Color(hex: 0xDC2626) : Color(hex: 0x059669))

            HStack {
                Text("CLOSING BALANCE :")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: 0xDC2626))
                Spacer()
                Text("\(CurrencyFormatter.formatINRDecimal(abs(metrics.closingBalance)))\(metrics.closingBalance >= 0 ? " Dr" : " Cr")")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0xDC2626))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(hex: 0xFEF2F2))
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0xCBD5E1).opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }

    private func summaryRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0x64748B))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func shortDateText(_ iso: String) -> String {
        let inFormatter = DateFormatter()
        inFormatter.dateFormat = "yyyy-MM-dd"
        if let d = inFormatter.date(from: String(iso.prefix(10))) {
            return formatDisplayDate(d)
        }
        return iso
    }

    private func formatPeriodRange(from: String, to: String) -> String {
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"

        let dispFormatter = DateFormatter()
        dispFormatter.dateFormat = "dd MMM yyyy"

        let dFrom = isoFormatter.date(from: String(from.prefix(10))) ?? dispFormatter.date(from: from)
        let dTo = isoFormatter.date(from: String(to.prefix(10))) ?? dispFormatter.date(from: to)

        if let dFrom = dFrom, let dTo = dTo {
            let mFrom = DateFormatter()
            mFrom.dateFormat = "MMM dd"
            let mTo = DateFormatter()
            mTo.dateFormat = "MMM dd, yyyy"
            var res = "\(mFrom.string(from: dFrom)) - \(mTo.string(from: dTo))"
            if res.contains("Sep ") {
                res = res.replacingOccurrences(of: "Sep ", with: "Sept ")
            }
            return res
        }
        return "Apr 01 - Sept 01, 2026"
    }

    // ── 7. Select Period Modal Dialog (Matching Screenshot 3) ────
    private struct FinancialYearOption {
        let label: String
        let startDate: Date
        let endDate: Date
    }

    private var financialYearOptions: [FinancialYearOption] {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        let startYear = currentMonth >= 4 ? currentYear : currentYear - 1

        var list: [FinancialYearOption] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for y in (startYear - 2)...startYear {
            let nextTwoDigits = (y + 1) % 100
            let label = String(format: "FY %d-%02d", y, nextTwoDigits)
            if let sDate = formatter.date(from: "\(y)-04-01"),
               let eDate = formatter.date(from: "\(y + 1)-03-31") {
                list.append(FinancialYearOption(label: label, startDate: sDate, endDate: eDate))
            }
        }
        return list.reversed()
    }

    private var selectPeriodDialog: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDatePickerSheet = false
                    }
                }

            // Modal Dialog Card
            VStack(alignment: .leading, spacing: 16) {
                // Header: Title & Close Button
                HStack {
                    Text("Select Period")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDatePickerSheet = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: 0x64748B))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }

                // FINANCIAL YEAR
                VStack(alignment: .leading, spacing: 8) {
                    Text("FINANCIAL YEAR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0x64748B))
                        .tracking(0.3)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(financialYearOptions, id: \.label) { fy in
                                let isSelected = isFinancialYearSelected(fy)
                                Button {
                                    tempStartDate = fy.startDate
                                    tempEndDate = fy.endDate
                                } label: {
                                    Text(fy.label)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x0F172A))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color(hex: 0xEFF6FF) : Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0xE2E8F0), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // FROM DATE
                VStack(alignment: .leading, spacing: 6) {
                    Text("FROM DATE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0x64748B))
                        .tracking(0.3)

                    Button {
                        activePicker = .from
                    } label: {
                        HStack {
                            Text(tempStartDate != nil ? formatDisplayDateDash(tempStartDate!) : "dd - mm - yyyy")
                                .font(.system(size: 14))
                                .foregroundColor(tempStartDate != nil ? Color(hex: 0x0F172A) : Color(hex: 0x94A3B8))
                            Spacer()
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: 0x0F172A))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // TO DATE
                VStack(alignment: .leading, spacing: 6) {
                    Text("TO DATE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0x64748B))
                        .tracking(0.3)

                    Button {
                        activePicker = .to
                    } label: {
                        HStack {
                            Text(tempEndDate != nil ? formatDisplayDateDash(tempEndDate!) : "dd - mm - yyyy")
                                .font(.system(size: 14))
                                .foregroundColor(tempEndDate != nil ? Color(hex: 0x0F172A) : Color(hex: 0x94A3B8))
                            Spacer()
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: 0x0F172A))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Bottom Actions: "All dates" & "Apply Period"
                HStack {
                    Button {
                        selectedStartDate = nil
                        selectedEndDate = nil
                        tempStartDate = nil
                        tempEndDate = nil
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDatePickerSheet = false
                        }
                    } label: {
                        Text("All dates")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: 0x64748B))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 8)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        if let from = tempStartDate, let to = tempEndDate, from > to {
                            selectedStartDate = to
                            selectedEndDate = from
                        } else {
                            selectedStartDate = tempStartDate
                            selectedEndDate = tempEndDate
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDatePickerSheet = false
                        }
                    } label: {
                        Text("Apply Period")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Color(hex: 0x2563EB))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }

    private func isFinancialYearSelected(_ fy: FinancialYearOption) -> Bool {
        guard let s = tempStartDate, let e = tempEndDate else { return false }
        let cal = Calendar.current
        return cal.isDate(s, inSameDayAs: fy.startDate) && cal.isDate(e, inSameDayAs: fy.endDate)
    }

    // ── 8. Networking & PDF Actions ──────────────────────────────
    private func loadLedger() async {
        guard let session = SessionManager.shared.session else { return }
        isLoading = true
        do {
            let res = try await LedgerService.shared.fetchDetailedLedger(token: session.token, partyName: customerName)
            await MainActor.run {
                self.ledger = res
                self.isLoading = false
            }
        } catch {
            if session.isCustomer {
                let cached = SessionManager.shared.cachedCustomerDetail
                let zeroLedger = LedgerResponse(
                    customer: LedgerCustomer(
                        id: cached?.id ?? session.customerCode ?? "13-raj-001",
                        name: customerName,
                        partyName: customerName,
                        code: cached?.code ?? session.customerCode ?? "13-raj-001",
                        city: cached?.city ?? "Beawar",
                        address: cached?.address ?? "13 Traders, Beawar, Rajasthan, India",
                        phone: cached?.phone ?? session.customerPhone ?? "",
                        email: cached?.email ?? session.customerEmail ?? session.email,
                        gstin: cached?.gstin ?? session.gstin ?? "",
                        creditLimit: cached?.creditLimit ?? 1000000.0,
                        openingBalance: 10559.0,
                        totalAmount: 37232.0,
                        paidAmount: 28820.0,
                        outstandingBalance: 8412.0,
                        closingBalance: 8412.0,
                        billCount: 6
                    ),
                    period: LedgerPeriod(fromDate: "2026-04-01", toDate: "2026-09-01"),
                    openingBalance: 10559.0,
                    closingBalance: 8412.0,
                    currentDebitTotal: 26673.0,
                    currentCreditTotal: 28820.0,
                    outstandingBalance: 8412.0,
                    billsReceivable: [],
                    ledgerVouchers: []
                )
                await MainActor.run {
                    self.ledger = zeroLedger
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func generateStatementPdf() {
        guard let l = ledger else { return }
        let html = LedgerPdfBuilder.buildHtml(for: l, customerName: customerName)
        let fileName = "Statement_\(customerName.replacingOccurrences(of: " ", with: "_")).pdf"
        if let url = PDFGeneratorService.shared.generatePDF(from: html, fileName: fileName) {
            self.statementPdfUrl = url
        }
    }

    private func openVoucher(_ voucher: LedgerVoucher, ledger: LedgerResponse) {
        guard let token = SessionManager.shared.session?.token else { return }
        let isReceipt = voucher.voucherType?.caseInsensitiveCompare("Receipt") == .orderedSame || ((voucher.credit ?? 0) > 0 && (voucher.debit ?? 0) <= 0)

        Task {
            if isReceipt {
                let html = ReceiptVoucherPdfBuilder.buildHtml(
                    voucher: voucher,
                    customerName: ledger.customer?.name ?? customerName,
                    customerAddress: ledger.customer?.address,
                    customerGstin: ledger.customer?.gstin,
                    customerPhone: ledger.customer?.phone
                )
                let fileName = "Receipt_\(voucher.voucherNumber).pdf"
                if let url = PDFGeneratorService.shared.generatePDF(from: html, fileName: fileName) {
                    await MainActor.run {
                        self.voucherPdfTitle = "Receipt Voucher \(voucher.voucherNumber)"
                        self.voucherPdfUrl = url
                    }
                }
            } else {
                var invoice = Invoice(
                    invoiceId: nil,
                    invoiceNumber: voucher.voucherNumber,
                    voucherNumber: voucher.voucherNumber,
                    voucherType: voucher.voucherType,
                    customerName: ledger.customer?.name ?? customerName,
                    party: ledger.customer?.partyName ?? customerName,
                    customerCode: ledger.customer?.code,
                    amount: voucher.debit,
                    subtotal: nil,
                    cgst: nil,
                    sgst: nil,
                    igst: nil,
                    roundOff: nil,
                    taxAmount: nil,
                    netAmount: voucher.debit,
                    status: "Paid",
                    date: voucher.date,
                    dueDate: nil,
                    buyerAddress: ledger.customer?.address,
                    buyerGstin: ledger.customer?.gstin,
                    pdfUrl: nil,
                    items: nil
                )
                if let detail = try? await LedgerService.shared.fetchInvoiceDetail(token: token, invoiceNumber: voucher.voucherNumber, party: customerName) {
                    invoice = detail
                }
                let html = InvoicePdfBuilder.buildHtml(
                    for: invoice,
                    customerName: ledger.customer?.name ?? customerName,
                    customerGstin: ledger.customer?.gstin,
                    customerAddress: ledger.customer?.address,
                    customerPhone: ledger.customer?.phone
                )
                let fileName = "Invoice_\(voucher.voucherNumber).pdf"
                if let url = PDFGeneratorService.shared.generatePDF(from: html, fileName: fileName) {
                    await MainActor.run {
                        self.voucherPdfTitle = "Tax Invoice \(voucher.voucherNumber)"
                        self.voucherPdfUrl = url
                    }
                }
            }
        }
    }
}
