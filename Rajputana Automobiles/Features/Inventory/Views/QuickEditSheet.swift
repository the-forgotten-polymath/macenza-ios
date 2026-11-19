import SwiftUI

public struct QuickEditInventorySheet: View {
    public let item: InventoryItem
    public var onSaved: (InventoryItem) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var stockLevel: String = ""
    @State private var minThreshold: String = ""
    @State private var dealerPrice: String = ""
    @State private var retailPrice: String = ""
    @State private var wholesalePrice: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    public init(item: InventoryItem, onSaved: @escaping (InventoryItem) -> Void) {
        self.item = item
        self.onSaved = onSaved
        _stockLevel = State(initialValue: String(format: "%.0f", item.effectiveStock))
        _minThreshold = State(initialValue: String(format: "%.0f", item.minThreshold ?? 10))
        _dealerPrice = State(initialValue: String(format: "%.2f", item.dealerPrice ?? 0))
        _retailPrice = State(initialValue: String(format: "%.2f", item.retailPrice ?? 0))
        _wholesalePrice = State(initialValue: String(format: "%.2f", item.wholesalePrice ?? 0))
    }

    public var body: some View {
        NavigationStack {
            Form {
                if let err = errorMessage {
                    Section {
                        Text(err).font(AppTypography.caption).foregroundColor(AppColors.red)
                    }
                }

                Section("Item Details") {
                    Text(item.displayName)
                        .font(AppTypography.headline)
                    Text("SKU: \(item.itemCode)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)
                }

                Section("Stock & Reorder Levels") {
                    TextField("Physical Stock (Units)", text: $stockLevel).keyboardType(.decimalPad)
                    TextField("Minimum Alert Threshold", text: $minThreshold).keyboardType(.decimalPad)
                }

                Section("Pricing Matrix (₹)") {
                    TextField("Dealer Net Price", text: $dealerPrice).keyboardType(.decimalPad)
                    TextField("Retail Price", text: $retailPrice).keyboardType(.decimalPad)
                    TextField("Wholesale Price", text: $wholesalePrice).keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Quick Edit Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveChanges() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func saveChanges() async {
        guard let token = SessionManager.shared.session?.token else { return }
        isSaving = true
        errorMessage = nil

        var changes: [String: Any] = [:]
        if let s = Double(stockLevel) { changes["stockLevel"] = s }
        if let m = Double(minThreshold) { changes["minThreshold"] = m }
        if let d = Double(dealerPrice) { changes["dealerPrice"] = d }
        if let r = Double(retailPrice) { changes["retailPrice"] = r }
        if let w = Double(wholesalePrice) { changes["wholesalePrice"] = w }

        do {
            let updated = try await InventoryService.shared.updateInventoryItem(token: token, id: item.id, changes: changes)
            await MainActor.run {
                isSaving = false
                onSaved(updated)
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
