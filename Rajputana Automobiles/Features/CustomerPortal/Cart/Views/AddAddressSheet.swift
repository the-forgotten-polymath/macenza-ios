import SwiftUI

public struct AddAddressSheet: View {
    public var onAdded: (DeliveryAddress) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var label: String = "Workshop Branch"
    @State private var recipientName: String = ""
    @State private var line1: String = ""
    @State private var line2: String = ""
    @State private var city: String = "Jaipur"
    @State private var state: String = "Rajasthan"
    @State private var pincode: String = ""
    @State private var phone: String = ""
    @State private var gstin: String = ""

    public init(onAdded: @escaping (DeliveryAddress) -> Void) {
        self.onAdded = onAdded
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Location Identifier") {
                    TextField("Address Label (e.g. Main Warehouse)", text: $label)
                    TextField("Recipient / Business Name", text: $recipientName)
                    TextField("Contact Phone", text: $phone).keyboardType(.phonePad)
                }

                Section("Street Address") {
                    TextField("Address Line 1", text: $line1)
                    TextField("Address Line 2 (Optional)", text: $line2)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("Pincode", text: $pincode).keyboardType(.numberPad)
                }

                Section("Tax ID (Optional)") {
                    TextField("GSTIN", text: $gstin).textInputAutocapitalization(.characters)
                }
            }
            .navigationTitle("Add Delivery Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newAddr = DeliveryAddress(
                            label: label,
                            isDefault: false,
                            recipientName: recipientName,
                            line1: line1,
                            line2: line2,
                            city: city,
                            state: state,
                            pincode: pincode,
                            phone: phone,
                            gstin: gstin.isEmpty ? nil : gstin
                        )
                        onAdded(newAddr)
                        dismiss()
                    }
                    .disabled(recipientName.isEmpty || line1.isEmpty || city.isEmpty || pincode.isEmpty)
                }
            }
        }
    }
}
