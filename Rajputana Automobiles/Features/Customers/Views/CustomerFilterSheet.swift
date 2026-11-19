import SwiftUI

public struct CustomerFilterSheet: View {
    public let customers: [Customer]
    public let options: CustomerFilterOptions
    public let initial: CustomerFilterState
    public var initialSection: FilterSection = .sort
    public var onApply: (CustomerFilterState) -> Void
    public var onDismiss: () -> Void

    @State private var draft: CustomerFilterState
    @State private var activeSection: FilterSection

    public init(
        customers: [Customer],
        options: CustomerFilterOptions,
        initial: CustomerFilterState,
        initialSection: FilterSection = .sort,
        onApply: @escaping (CustomerFilterState) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.customers = customers
        self.options = options
        self.initial = initial
        self.initialSection = initialSection
        self.onApply = onApply
        self.onDismiss = onDismiss
        _draft = State(initialValue: initial)
        _activeSection = State(initialValue: initialSection)
    }

    private var matchingRecordsCount: Int {
        customers.count { $0.matchesFilters(draft) }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── Top Header ─────────────────────────────────────────
            HStack(alignment: .center, spacing: 8) {
                Text("Filters")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Text("\(matchingRecordsCount.formatted()) records")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                Button("Reset All") {
                    draft = CustomerFilterState()
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: 0x2563EB))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider()
                .background(Color(hex: 0xE2E8F0))

            // ── Two-Pane Main Layout ───────────────────────────────
            HStack(spacing: 0) {
                // Left Navigation Rail
                VStack(spacing: 0) {
                    ForEach(FilterSection.allCases) { section in
                        let isSelected = activeSection == section

                        Button {
                            activeSection = section
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(section.title)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                                    .foregroundColor(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x0F172A))

                                Text(subtitleFor(section))
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x64748B))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isSelected ? Color(hex: 0xEFF6FF) : Color(hex: 0xF8FAFC))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .background(Color(hex: 0xF1F5F9))
                    }

                    Spacer()
                }
                .frame(width: 125)
                .background(Color(hex: 0xF8FAFC))

                Divider()
                    .background(Color(hex: 0xE2E8F0))

                // Right Options Pane
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        switch activeSection {
                        case .sort:
                            sortSectionView
                        case .status:
                            statusSectionView
                        case .balance:
                            balanceSectionView
                        case .groups:
                            groupsSectionView
                        case .cities:
                            citiesSectionView
                        }
                    }
                    .padding(16)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
            }

            Divider()
                .background(Color(hex: 0xE2E8F0))

            // ── Bottom Action Bar ──────────────────────────────────
            HStack {
                Button("Clear Filter") {
                    draft = CustomerFilterState()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: 0x64748B))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Spacer()

                Button {
                    onApply(draft)
                    onDismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Apply")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0x2563EB))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .onAppear {
            activeSection = initialSection
        }
    }

    private func subtitleFor(_ section: FilterSection) -> String {
        switch section {
        case .sort:
            return draft.sort.chipLabel
        case .status:
            return draft.status == .all ? "All" : draft.status.rawValue
        case .balance:
            return draft.balance == .all ? "All" : draft.balance.rawValue
        case .groups:
            return draft.groups.isEmpty ? "All" : "\(draft.groups.count) selected"
        case .cities:
            return draft.cities.isEmpty ? "All" : "\(draft.cities.count) selected"
        }
    }

    // ── 1. Sort Section (Screenshot 2) ─────────────────────────────
    private var sortSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SELECT ORDERING")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))
                Spacer()
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x94A3B8))
            }
            .padding(.bottom, 6)

            ForEach(CustomerSort.allCases) { sort in
                let isSelected = draft.sort == sort
                Button {
                    draft.sort = sort
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0xCBD5E1), lineWidth: isSelected ? 6 : 1.5)
                                .frame(width: 18, height: 18)
                        }

                        Text(sort.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x0F172A))

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: 0x2563EB))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(isSelected ? Color(hex: 0xEFF6FF) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color(hex: 0xBFDBFE) : Color.clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // ── 2. Account Status Section (Screenshot 3) ───────────────────
    private var statusSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CUSTOMER STATUS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))
                Spacer()
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x94A3B8))
            }
            .padding(.bottom, 6)

            ForEach(AccountStatusFilter.allCases) { status in
                let isSelected = draft.status == status
                let count = options.statusCounts[status] ?? 0

                Button {
                    draft.status = status
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .stroke(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0xCBD5E1), lineWidth: isSelected ? 6 : 1.5)
                            .frame(width: 18, height: 18)

                        Text(status.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x0F172A))

                        Spacer()

                        Text(count.formatted())
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: 0x64748B))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(isSelected ? Color(hex: 0xEFF6FF) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color(hex: 0xBFDBFE) : Color.clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // ── 3. Balance Section (Screenshot 4) ──────────────────────────
    private var balanceSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("LEDGER POSITION")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))
                Spacer()
                Image(systemName: "wallet.pass")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x94A3B8))
            }
            .padding(.bottom, 6)

            ForEach(BalanceFilter.allCases) { bal in
                let isSelected = draft.balance == bal
                let count = options.balanceCounts[bal] ?? 0

                Button {
                    draft.balance = bal
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        Circle()
                            .stroke(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0xCBD5E1), lineWidth: isSelected ? 6 : 1.5)
                            .frame(width: 18, height: 18)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(bal.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x0F172A))

                            if !bal.hint.isEmpty {
                                Text("\(bal.hint) · \(count.formatted())")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(Color(hex: 0x64748B))
                            } else {
                                Text("\(count.formatted()) total ledger records")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(Color(hex: 0x64748B))
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(isSelected ? Color(hex: 0xEFF6FF) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color(hex: 0xBFDBFE) : Color.clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // ── 4. Tally Groups Section (Screenshot 5) ─────────────────────
    private var groupsSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SALES IN-CHARGE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: 0x64748B))
                .padding(.bottom, 6)

            ForEach(options.groups) { grp in
                let isChecked = draft.groups.contains(grp.key)

                Button {
                    if isChecked {
                        draft.groups.remove(grp.key)
                    } else {
                        draft.groups.insert(grp.key)
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isChecked ? Color(hex: 0x2563EB) : Color(hex: 0xCBD5E1), lineWidth: 1.5)
                                .frame(width: 18, height: 18)

                            if isChecked {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: 0x2563EB))
                                    .frame(width: 18, height: 18)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(grp.label)
                            .font(.system(size: 13, weight: isChecked ? .semibold : .regular))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)

                        Spacer()

                        Text(grp.count.formatted())
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: 0x64748B))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // ── 5. Cities / Hubs Section (Screenshot 6) ────────────────────
    private var citiesSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SELECT HUBS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))

                Spacer()

                let allSelected = !options.cities.isEmpty && draft.cities.count == options.cities.count
                Button(allSelected ? "Deselect All" : "Select All") {
                    if allSelected {
                        draft.cities.removeAll()
                    } else {
                        draft.cities = Set(options.cities.map { $0.key })
                    }
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: 0x2563EB))
            }
            .padding(.bottom, 6)

            ForEach(options.cities) { city in
                let isChecked = draft.cities.contains(city.key)

                Button {
                    if isChecked {
                        draft.cities.remove(city.key)
                    } else {
                        draft.cities.insert(city.key)
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isChecked ? Color(hex: 0x2563EB) : Color(hex: 0xCBD5E1), lineWidth: 1.5)
                                .frame(width: 18, height: 18)

                            if isChecked {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: 0x2563EB))
                                    .frame(width: 18, height: 18)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(city.label)
                            .font(.system(size: 13, weight: isChecked ? .semibold : .regular))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)

                        Spacer()

                        Text(city.count.formatted())
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: 0x64748B))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
