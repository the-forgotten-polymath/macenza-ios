import SwiftUI

private enum InventoryFilterSection {
    case sort
    case category
    case price
}

public struct InventoryFilterSheet: View {
    @Bindable public var viewModel: InventoryViewModel
    public var onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var draftSort: InventorySort
    @State private var draftCategories: Set<String>
    @State private var draftMinPrice: String
    @State private var draftMaxPrice: String
    @State private var draftOnlyZero: Bool
    @State private var currentSection: InventoryFilterSection

    public init(
        viewModel: InventoryViewModel,
        onApply: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onApply = onApply

        _draftSort = State(initialValue: viewModel.selectedSort)
        _draftCategories = State(initialValue: viewModel.selectedCategories)
        _draftMinPrice = State(initialValue: viewModel.minPrice)
        _draftMaxPrice = State(initialValue: viewModel.maxPrice)
        _draftOnlyZero = State(initialValue: viewModel.onlyZeroPrice)
        _currentSection = State(initialValue: ProcessInfo.processInfo.arguments.contains("-filterCategory") ? .category : (ProcessInfo.processInfo.arguments.contains("-filterPrice") ? .price : .sort))
    }

    private var isPriceFiltered: Bool {
        !draftMinPrice.trimmingCharacters(in: .whitespaces).isEmpty ||
        !draftMaxPrice.trimmingCharacters(in: .whitespaces).isEmpty ||
        draftOnlyZero
    }

    private var zeroPriceCount: Int {
        viewModel.items.count { ($0.unitPrice ?? 0.0) <= 0.0 }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(hex: 0xCBD5E1))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 6)

            // Header
            HStack(spacing: 10) {
                Text("Filters")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Text("\(formatCount(viewModel.items.count)) records")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                Button("Reset All") {
                    draftSort = .nameAToZ
                    draftCategories = []
                    draftMinPrice = ""
                    draftMaxPrice = ""
                    draftOnlyZero = false
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: 0x2563EB))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)

            Divider().background(Color(hex: 0xE2E8F0))

            // Body: Two-pane layout
            HStack(spacing: 0) {
                // Left Rail
                VStack(spacing: 0) {
                    leftRailButton(
                        section: .sort,
                        title: "Sort By",
                        subtitle: draftSort.label,
                        isHighlighted: draftSort != .nameAToZ
                    )

                    leftRailButton(
                        section: .category,
                        title: "Category",
                        subtitle: draftCategories.isEmpty ? "All" : "\(draftCategories.count) selected",
                        isHighlighted: !draftCategories.isEmpty
                    )

                    leftRailButton(
                        section: .price,
                        title: "Price",
                        subtitle: isPriceFiltered ? "Filtered" : "All",
                        isHighlighted: isPriceFiltered
                    )

                    Spacer()
                }
                .frame(width: 135)
                .background(Color(hex: 0xF8FAFC))
                .overlay(
                    Rectangle()
                        .fill(Color(hex: 0xE2E8F0))
                        .frame(width: 1),
                    alignment: .trailing
                )

                // Right Pane
                VStack(spacing: 0) {
                    switch currentSection {
                    case .sort:
                        sortPane
                    case .category:
                        categoryPane
                    case .price:
                        pricePane
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
            .frame(maxHeight: .infinity)

            Divider().background(Color(hex: 0xE2E8F0))

            // Bottom action footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: 0x64748B))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                Spacer()

                Button(action: {
                    viewModel.selectedSort = draftSort
                    viewModel.selectedCategories = draftCategories
                    viewModel.minPrice = draftMinPrice
                    viewModel.maxPrice = draftMaxPrice
                    viewModel.onlyZeroPrice = draftOnlyZero
                    onApply()
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                        Text("Apply Filters")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0x2563EB))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    // ── Left Rail Button ──────────────────────────────────────
    private func leftRailButton(section: InventoryFilterSection, title: String, subtitle: String, isHighlighted: Bool) -> some View {
        let isSelected = currentSection == section
        return Button {
            currentSection = section
        } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(isSelected ? Color(hex: 0x2563EB) : Color.clear)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x0F172A))

                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(isHighlighted || isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x64748B))
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)

                Spacer()
            }
            .background(isSelected ? Color.white : Color(hex: 0xF8FAFC))
        }
        .buttonStyle(.plain)
    }

    // ── Sort Pane ─────────────────────────────────────────────
    private var sortPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("SELECT ORDERING")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))
                    .padding(.bottom, 4)

                let availableSorts: [InventorySort] = [
                    .stockHighToLow,
                    .stockLowToHigh,
                    .priceHighToLow,
                    .priceLowToHigh,
                    .nameAToZ
                ]

                ForEach(availableSorts) { option in
                    let isChosen = draftSort == option
                    Button {
                        draftSort = option
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(.system(size: 13, weight: isChosen ? .bold : .medium))
                                .foregroundColor(isChosen ? Color(hex: 0x2563EB) : Color(hex: 0x0F172A))

                            Spacer()

                            ZStack {
                                Circle()
                                    .stroke(isChosen ? Color(hex: 0x2563EB) : Color(hex: 0xCBD5E1), lineWidth: 2)
                                    .frame(width: 20, height: 20)

                                if isChosen {
                                    Circle()
                                        .fill(Color(hex: 0x2563EB))
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(isChosen ? Color(hex: 0xEFF6FF) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
        }
    }

    // ── Category Pane ─────────────────────────────────────────
    private var categoryPane: some View {
        VStack(spacing: 0) {
            let counts = viewModel.categoryCounts
            let allSelected = !counts.isEmpty && counts.allSatisfy { draftCategories.contains($0.name) }

            HStack {
                Text("STOCK CATEGORIES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))

                Spacer()

                Button(allSelected ? "Clear" : "Select All") {
                    if allSelected {
                        draftCategories.removeAll()
                    } else {
                        draftCategories = Set(counts.map { $0.name })
                    }
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: 0x2563EB))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(counts, id: \.name) { cat in
                        let isChecked = draftCategories.contains(cat.name)
                        Button {
                            if isChecked {
                                draftCategories.remove(cat.name)
                            } else {
                                draftCategories.insert(cat.name)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(isChecked ? Color(hex: 0x2563EB) : Color(hex: 0xCBD5E1), lineWidth: 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(isChecked ? Color(hex: 0x2563EB) : Color.white)
                                        )
                                        .frame(width: 20, height: 20)

                                    if isChecked {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }

                                Text(cat.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: 0x0F172A))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Text("\(cat.count)")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(Color(hex: 0x64748B))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(isChecked ? Color(hex: 0xEFF6FF) : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isChecked ? Color(hex: 0x2563EB).opacity(0.35) : Color(hex: 0xE2E8F0), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
    }

    // ── Price Pane ────────────────────────────────────────────
    private var pricePane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("PRICE RANGE (₹)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))

                Text("Min Price")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x64748B))

                HStack {
                    Text("₹")
                        .foregroundColor(Color(hex: 0x64748B))
                    TextField("0", text: $draftMinPrice)
                        .keyboardType(.numberPad)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))

                Text("Max Price")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x64748B))

                HStack {
                    Text("₹")
                        .foregroundColor(Color(hex: 0x64748B))
                    TextField("No limit", text: $draftMaxPrice)
                        .keyboardType(.numberPad)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))

                Button(action: {
                    draftMinPrice = ""
                    draftMaxPrice = ""
                    draftOnlyZero = false
                }) {
                    Text("Clear Price Filter")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: 0x2563EB))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
                }
                .padding(.top, 4)

                // Show only 0 price items
                Button {
                    draftOnlyZero.toggle()
                } label: {
                    HStack {
                        Text("Show only 0 price items (\(zeroPriceCount))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)

                        Spacer()

                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(draftOnlyZero ? Color(hex: 0x2563EB) : Color(hex: 0xCBD5E1), lineWidth: 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(draftOnlyZero ? Color(hex: 0x2563EB) : Color.white)
                                )
                                .frame(width: 18, height: 18)

                            if draftOnlyZero {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 46)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
    }

    private func formatCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
}
