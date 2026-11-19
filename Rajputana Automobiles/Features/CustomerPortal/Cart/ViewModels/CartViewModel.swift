import Foundation
import SwiftUI

public enum CheckoutStep: Int, CaseIterable {
    case cart = 0
    case address = 1
    case payment = 2
    case confirmed = 3

    public var title: String {
        switch self {
        case .cart: return "My Cart"
        case .address: return "Delivery Address"
        case .payment: return "Payment"
        case .confirmed: return "Order Placed"
        }
    }
}

@Observable
public final class CartViewModel {
    public static let shared = CartViewModel()

    public var currentStep: CheckoutStep = .cart
    public var items: [CartApiItem] = []
    public var inventorySnapshot: [InventoryItem] = []

    // Saved delivery addresses (local storage)
    public var addresses: [DeliveryAddress] = [
        DeliveryAddress(
            label: "Primary Workshop & Spares Depot",
            isDefault: true,
            recipientName: "M/s Bharat Bearing & Engineering Works",
            line1: "Plot 42, Heavy Industrial Area, Phase II",
            city: "Jaipur",
            state: "Rajasthan",
            pincode: "302013",
            phone: "+91 98290 12345"
        ),
        DeliveryAddress(
            label: "Central Service Hub",
            isDefault: false,
            recipientName: "Bharat Spares Hub",
            line1: "Shop 14, Transport Nagar",
            city: "Ajmer",
            state: "Rajasthan",
            pincode: "305001",
            phone: "+91 94140 54321"
        )
    ]
    public var selectedAddressId: String = ""

    public var isLoading: Bool = false
    public var isPlacingOrder: Bool = false
    public var confirmedOrderNumber: String = ""
    public var confirmedOrderTotal: Double = 0.0
    public var errorMessage: String? = nil
    public var alertMessage: String? = nil

    public init() {
        if let first = addresses.first {
            selectedAddressId = first.id
        }
    }

    public var subtotal: Double {
        return items.reduce(0.0) { $0 + $1.lineTotal }
    }

    public var gstAmount: Double {
        return round((subtotal * 0.18) * 100) / 100.0
    }

    public var netTotal: Double {
        return subtotal + gstAmount
    }

    public var totalUnits: Int {
        return items.reduce(0) { $0 + $1.quantity }
    }

    public var selectedAddress: DeliveryAddress? {
        return addresses.first { $0.id == selectedAddressId } ?? addresses.first
    }

    public func loadCart() async {
        if ProcessInfo.processInfo.arguments.contains("-mockCartItem") {
            await MainActor.run {
                self.items = [
                    CartApiItem(
                        id: "mock-1",
                        name: "Alternaror-A115-35 TRACTORS SONALIKA",
                        partNumber: "26021304",
                        oemCode: "26021304",
                        brand: "Alternator",
                        dealerPrice: 4250.0,
                        quantity: 10
                    ),
                    CartApiItem(
                        id: "mock-2",
                        name: "Alternator L/L HINO 24VL",
                        partNumber: "26021668",
                        oemCode: "26021668",
                        brand: "Alternator",
                        dealerPrice: 5800.0,
                        quantity: 3
                    )
                ]
                self.isLoading = false
                SessionManager.shared.updateCartCount(self.totalUnits)
            }
            return
        }

        guard let session = SessionManager.shared.session else { return }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let fetched = try await CartService.shared.fetchCart(
                token: session.token,
                identifier: session.effectiveCustomerIdentifier
            )
            await MainActor.run {
                self.items = fetched
                self.isLoading = false
                SessionManager.shared.updateCartCount(self.totalUnits)
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    public func addToCart(product: InventoryItem, quantity: Int = 1) async -> Bool {
        guard let session = SessionManager.shared.session else { return false }

        // Client-side stock safeguard: backend does not reject out-of-stock items
        let availableStock = product.effectiveStock
        let existingQty = items.first(where: { $0.id == product.id || $0.partNumber == product.itemCode })?.quantity ?? 0

        if Double(existingQty + quantity) > availableStock {
            await MainActor.run {
                self.alertMessage = "Cannot add \(quantity) units. Only \(Int(availableStock)) units available in warehouse."
            }
            return false
        }

        var updated = items
        if let index = updated.firstIndex(where: { $0.id == product.id || $0.partNumber == product.itemCode }) {
            updated[index].quantity += quantity
        } else {
            let newItem = CartApiItem(
                id: product.id,
                name: product.displayName,
                partNumber: product.itemCode,
                oemCode: product.itemCode,
                brand: product.primaryGroup ?? "General",
                fits: product.vehicleSegment ?? "4-Wheeler",
                dealerPrice: product.effectivePrice,
                boxPack: 1,
                quantity: quantity,
                imageUrl: product.bestImage
            )
            updated.append(newItem)
        }

        self.items = updated
        SessionManager.shared.updateCartCount(totalUnits)

        // Sync with server
        Task {
            try? await CartService.shared.saveCart(
                token: session.token,
                identifier: session.effectiveCustomerIdentifier,
                customerName: session.name,
                items: updated
            )
        }

        return true
    }

    public func updateQuantity(itemId: String, newQty: Int) {
        guard let session = SessionManager.shared.session else { return }

        if newQty <= 0 {
            removeItem(itemId: itemId)
            return
        }

        if let index = items.firstIndex(where: { $0.id == itemId }) {
            // Validate against snapshot if present
            if let snap = inventorySnapshot.first(where: { $0.id == itemId || $0.itemCode == items[index].partNumber }) {
                if Double(newQty) > snap.effectiveStock {
                    self.alertMessage = "Stock limit reached. Maximum \(Int(snap.effectiveStock)) units available."
                    return
                }
            }

            items[index].quantity = newQty
            SessionManager.shared.updateCartCount(totalUnits)

            Task {
                try? await CartService.shared.saveCart(
                    token: session.token,
                    identifier: session.effectiveCustomerIdentifier,
                    customerName: session.name,
                    items: items
                )
            }
        }
    }

    public func removeItem(itemId: String) {
        guard let session = SessionManager.shared.session else { return }
        items.removeAll { $0.id == itemId }
        SessionManager.shared.updateCartCount(totalUnits)

        Task {
            try? await CartService.shared.saveCart(
                token: session.token,
                identifier: session.effectiveCustomerIdentifier,
                customerName: session.name,
                items: items
            )
        }
    }

    public func clearCart() {
        guard let session = SessionManager.shared.session else { return }
        items.removeAll()
        SessionManager.shared.updateCartCount(0)

        Task {
            try? await CartService.shared.clearCart(
                token: session.token,
                identifier: session.effectiveCustomerIdentifier
            )
        }
    }

    public func reorderItems(orderItems: [OrderItem], inventory: [InventoryItem]) async -> (addedCount: Int, skippedCount: Int, message: String) {
        guard let session = SessionManager.shared.session else {
            return (0, 0, "Please login to reorder")
        }

        var plannedItems = items
        var addedCount = 0
        var skippedCount = 0
        var issueNotes: [String] = []

        for line in orderItems {
            let sku = (line.itemCode ?? line.itemId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sku.isEmpty else {
                skippedCount += 1
                continue
            }

            let skuLower = sku.lowercased()

            // Find matching inventory item
            guard let inv = inventory.first(where: { item in
                if item.itemCode.lowercased() == skuLower { return true }
                if item.id.lowercased() == skuLower { return true }
                if item.mongoId.lowercased() == skuLower { return true }
                return false
            }) else {
                skippedCount += 1
                issueNotes.append("\(line.displayName) (no longer in catalog)")
                continue
            }

            let maxStock = Int(inv.effectiveStock)
            if maxStock <= 0 {
                skippedCount += 1
                issueNotes.append("\(line.displayName) (out of stock)")
                continue
            }

            let requestedQty = line.effectiveQuantity
            let existingIdx = plannedItems.firstIndex(where: { cartItem in
                cartItem.partNumber.lowercased() == skuLower || cartItem.id == inv.id
            })
            let currentInCart = existingIdx != nil ? plannedItems[existingIdx!].quantity : 0
            let availableToAdd = maxStock - currentInCart

            if availableToAdd <= 0 {
                skippedCount += 1
                issueNotes.append("\(line.displayName) (cart has maximum stock of \(maxStock))")
                continue
            }

            let qtyToAdd = min(requestedQty, availableToAdd)
            if let idx = existingIdx {
                plannedItems[idx].quantity += qtyToAdd
            } else {
                let newItem = CartApiItem(
                    id: inv.id,
                    name: inv.displayName,
                    partNumber: inv.itemCode,
                    oemCode: inv.itemCode,
                    brand: inv.primaryGroup ?? "General",
                    fits: inv.vehicleSegment ?? "4-Wheeler",
                    dealerPrice: inv.effectivePrice,
                    boxPack: 1,
                    quantity: qtyToAdd,
                    imageUrl: inv.bestImage
                )
                plannedItems.append(newItem)
            }
            addedCount += 1
        }

        if addedCount > 0 {
            self.items = plannedItems
            SessionManager.shared.updateCartCount(totalUnits)
            Task {
                try? await CartService.shared.saveCart(
                    token: session.token,
                    identifier: session.effectiveCustomerIdentifier,
                    customerName: session.name,
                    items: plannedItems
                )
            }
        }

        let summaryMessage: String
        if addedCount > 0 && skippedCount == 0 {
            summaryMessage = "Added \(addedCount) items to your cart."
        } else if addedCount > 0 {
            summaryMessage = "Added \(addedCount) items. Skipped \(skippedCount): " + issueNotes.prefix(2).joined(separator: ", ")
        } else {
            summaryMessage = "Could not add items: " + issueNotes.prefix(2).joined(separator: ", ")
        }

        return (addedCount, skippedCount, summaryMessage)
    }

    public func placeOrder() async -> Bool {
        guard let session = SessionManager.shared.session else { return false }
        guard let shipping = selectedAddress else {
            errorMessage = "Please select or add a delivery address."
            return false
        }
        guard !items.isEmpty else {
            errorMessage = "Your cart is empty."
            return false
        }

        await MainActor.run {
            self.isPlacingOrder = true
            self.errorMessage = nil
        }

        do {
            let res = try await CartService.shared.placeOrder(
                token: session.token,
                session: session,
                items: items,
                shipping: shipping
            )

            await MainActor.run {
                self.isPlacingOrder = false
                self.confirmedOrderNumber = res.orderNumber ?? res.id ?? "ORD-\(Int.random(in: 1000...9999))"
                self.confirmedOrderTotal = self.netTotal
                self.items.removeAll()
                SessionManager.shared.updateCartCount(0)
                self.currentStep = .confirmed
            }
            return true
        } catch {
            await MainActor.run {
                self.isPlacingOrder = false
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
}
