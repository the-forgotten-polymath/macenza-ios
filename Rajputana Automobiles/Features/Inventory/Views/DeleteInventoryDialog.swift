import SwiftUI

public struct DeleteInventoryDialog: View {
    public let item: InventoryItem
    public var isDeleting: Bool
    public var onCancel: () -> Void
    public var onConfirm: () -> Void

    public init(
        item: InventoryItem,
        isDeleting: Bool,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) {
        self.item = item
        self.isDeleting = isDeleting
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isDeleting { onCancel() }
                }

            VStack(spacing: 16) {
                // Warning icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: 0xFEE2E2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(hex: 0xDC2626))
                }
                .padding(.top, 4)

                // Title
                Text("Delete Product Item?")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                // Body
                Text("Are you sure you want to delete **\"\(item.displayName)\"** (**\(item.itemCode)**) from live warehouse stock? This action cannot be undone.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0x64748B))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 4)

                // Actions
                HStack(spacing: 10) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color(hex: 0xF1F5F9))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isDeleting)

                    Button(action: onConfirm) {
                        HStack(spacing: 6) {
                            if isDeleting {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                                Text("Deleting...")
                                    .font(.system(size: 14, weight: .semibold))
                            } else {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14))
                                Text("Confirm Delete")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color(hex: 0xE11D48))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isDeleting)
                }
                .padding(.top, 8)
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
    }
}
