import SwiftUI

public struct DomainCategoryItem: Identifiable, Hashable {
    public var id: String { "\(domain)_\(category)" }
    public let domain: String
    public let category: String
    public let count: Int
}

public struct DomainGroup: Identifiable {
    public var id: String { domain }
    public let domain: String
    public let totalCount: Int
    public let categories: [DomainCategoryItem]
}

@Observable
public final class CategoryAccordionViewModel {
    public var isLoading: Bool = false
    public var searchText: String = ""
    public var domainGroups: [DomainGroup] = []
    public var expandedDomains: Set<String> = []
    public var errorMessage: String? = nil

    private var allInventory: [InventoryItem] = []

    public init() {}

    public func loadData(force: Bool = false) async {
        guard let session = SessionManager.shared.session else { return }

        await MainActor.run {
            self.isLoading = allInventory.isEmpty
            self.errorMessage = nil
        }

        do {
            let items = try await InventoryService.shared.fetchInventory(token: session.token)
            await MainActor.run {
                self.allInventory = items
                self.processGroups()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    public func toggleDomain(_ domain: String) {
        if expandedDomains.contains(domain) {
            expandedDomains.remove(domain)
        } else {
            expandedDomains.insert(domain)
        }
    }

    public func updateSearch(_ text: String) {
        searchText = text
        processGroups()
        if !text.trimmingCharacters(in: .whitespaces).isEmpty {
            expandedDomains = Set(domainGroups.map { $0.domain })
        }
    }

    private func processGroups() {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()

        var domainMap: [String: [String: Int]] = [:]

        for item in allInventory {
            let domain = (item.systemDomain ?? "General").trimmingCharacters(in: .whitespaces)
            let cat = (item.category ?? item.stockGroup ?? "General").trimmingCharacters(in: .whitespaces)
            let effectiveDomain = domain.isEmpty ? "General" : domain
            let effectiveCat = cat.isEmpty ? "General" : cat

            if !query.isEmpty {
                let textToMatch = "\(effectiveDomain) \(effectiveCat) \(item.itemCode) \(item.displayName)".lowercased()
                if !textToMatch.contains(query) {
                    continue
                }
            }

            domainMap[effectiveDomain, default: [:]][effectiveCat, default: 0] += 1
        }

        var groups: [DomainGroup] = []
        for (domain, catMap) in domainMap {
            var catItems: [DomainCategoryItem] = []
            var total = 0
            for (cat, count) in catMap {
                catItems.append(DomainCategoryItem(domain: domain, category: cat, count: count))
                total += count
            }
            catItems.sort { $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending }
            groups.append(DomainGroup(domain: domain, totalCount: total, categories: catItems))
        }

        groups.sort { $0.totalCount > $1.totalCount }
        self.domainGroups = groups
    }
}

public struct CategoryAccordionView: View {
    @State private var viewModel = CategoryAccordionViewModel()
    @State private var selectedDestination: DomainCategoryItem? = nil

    public init() {}

    public var body: some View {
        ZStack {
            Color(hex: 0xF8FAFC).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    // 1. Catalog Header Card matching Android CatalogHeader
                    catalogHeaderCard
                        .padding(.top, 4)

                    // 2. Search Field matching Android CatalogSearchField
                    searchBar

                    // Match status if searching
                    if !viewModel.searchText.isEmpty && !viewModel.domainGroups.isEmpty {
                        let totalCats = viewModel.domainGroups.reduce(0) { $0 + $1.categories.count }
                        let totalSkus = viewModel.domainGroups.reduce(0) { $0 + $1.totalCount }
                        HStack {
                            Text("\(totalCats) categories • \(totalSkus) SKUs match")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: 0x64748B))
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }

                    // 3. Domain Accordion List
                    if viewModel.isLoading && viewModel.domainGroups.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(0..<6, id: \.self) { _ in
                                ShimmerBox(height: 54, cornerRadius: 12)
                            }
                        }
                    } else if viewModel.domainGroups.isEmpty {
                        VStack(spacing: 10) {
                            Spacer().frame(height: 40)
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: 0x94A3B8))
                            Text("No categories found")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: 0x0F172A))
                            Text("Try searching for different keywords.")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: 0x64748B))
                            Spacer().frame(height: 40)
                        }
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.domainGroups) { group in
                                domainAccordionCard(group: group)
                            }
                        }
                    }

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .refreshable {
                await viewModel.loadData(force: true)
            }
        }
        .navigationDestination(item: $selectedDestination) { destination in
            CategoryDetailView(
                systemDomain: destination.domain,
                selectedCategory: destination.category
            )
        }
        .task {
            await viewModel.loadData()
        }
    }

    // ── 1. Catalog Header Card ───────────────────────────────────
    private var catalogHeaderCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Rajputana Auto Catalog")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Text("ERP Active")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: 0xDBEAFE))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x2563EB))
                    Text("OEM Certified")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: 0x2563EB))
                }
            }

            Text("Master component inventory for Bay 4 workshop. Tap any category card below to inspect stock & spares in vertical browser mode.")
                .font(.system(size: 11.5))
                .foregroundColor(Color(hex: 0x64748B))
                .lineSpacing(3)
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

    // ── 2. Search Field ──────────────────────────────────────────
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0x94A3B8))

            TextField("Search parts, OEM numbers, or categories...", text: Binding(
                get: { viewModel.searchText },
                set: { viewModel.updateSearch($0) }
            ))
            .font(.system(size: 13))
            .foregroundColor(Color(hex: 0x0F172A))
            .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.updateSearch("")
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

    // ── 3. Domain Accordion Card ─────────────────────────────────
    private func domainAccordionCard(group: DomainGroup) -> some View {
        let isExpanded = viewModel.expandedDomains.contains(group.domain)

        return VStack(spacing: 0) {
            // Header Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.toggleDomain(group.domain)
                }
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: 0x2563EB))
                        .frame(width: 8, height: 8)

                    Text(group.domain.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))
                        .lineLimit(1)

                    Text("\(group.categories.count) \(group.categories.count == 1 ? "Category" : "Categories")")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: 0x2563EB))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0xDBEAFE))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Spacer()

                    Text("\(group.totalCount) SKUs")
                        .font(.system(size: 11.5))
                        .foregroundColor(Color(hex: 0x64748B))

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                            )

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: 0x64748B))
                    }
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            // Expanded 3-Column Category Grid matching Android CategoryCard
            if isExpanded {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    ForEach(group.categories) { cat in
                        categoryCardItem(cat)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }

    // ── 4. Category Tile Card (3-Column Grid) ────────────────────
    private func categoryCardItem(_ cat: DomainCategoryItem) -> some View {
        Button {
            selectedDestination = cat
        } label: {
            VStack(spacing: 0) {
                Text(cat.category)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 34, alignment: .center)
                    .padding(.top, 10)
                    .padding(.horizontal, 6)

                Spacer().frame(height: 6)

                // SKU count pill
                Text("\(cat.count) SKUs")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: 0xD3E5FE), lineWidth: 1)
                    )

                Spacer().frame(height: 12)

                // Browse > Button
                HStack(spacing: 2) {
                    Text("Browse")
                        .font(.system(size: 11, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(Color(hex: 0x2563EB))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: 0xE8EDF3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
