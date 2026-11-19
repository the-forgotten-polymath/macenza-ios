import SwiftUI

public struct AddressStepView: View {
    @Bindable var viewModel: CartViewModel
    public var onProceed: () -> Void

    @State private var showAddSheet: Bool = false

    public init(viewModel: CartViewModel, onProceed: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onProceed = onProceed
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    HStack {
                        Text("Select Delivery Destination")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textDark)
                        Spacer()
                        Button(action: { showAddSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("New Address")
                            }
                            .font(AppTypography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primary)
                        }
                    }
                    .padding(.top, 4)

                    ForEach(viewModel.addresses) { addr in
                        addressCard(addr)
                    }

                    Spacer().frame(height: 80)
                }
                .padding(16)
            }

            // Bottom proceed
            VStack(spacing: 8) {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Deliver to")
                            .font(AppTypography.micro)
                            .foregroundColor(AppColors.textMuted)
                        Text(viewModel.selectedAddress?.city ?? "Select address")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textDark)
                    }

                    Spacer()

                    Button(action: onProceed) {
                        HStack {
                            Text("Proceed to Payment")
                            Image(systemName: "arrow.right")
                        }
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 48)
                        .background(AppColors.primary)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.selectedAddress == nil)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(AppColors.cardBackground)
        }
        .sheet(isPresented: $showAddSheet) {
            AddAddressSheet { newAddr in
                viewModel.addresses.append(newAddr)
                viewModel.selectedAddressId = newAddr.id
            }
        }
    }

    private func addressCard(_ addr: DeliveryAddress) -> some View {
        let isSelected = viewModel.selectedAddressId == addr.id
        return Button(action: {
            viewModel.selectedAddressId = addr.id
        }) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textLight)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(addr.label)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textDark)

                        Spacer()

                        if addr.isDefault {
                            StatusBadge(text: "Default", style: .info)
                        }
                    }

                    Text(addr.recipientName)
                        .font(AppTypography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textBody)

                    Text(addr.fullAddress)
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textMuted)

                    Label(addr.phone, systemImage: "phone.fill")
                        .font(AppTypography.micro)
                        .foregroundColor(AppColors.textBody)
                        .padding(.top, 2)
                }
            }
            .padding(14)
            .background(isSelected ? AppColors.primaryBgLight.opacity(0.4) : AppColors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
