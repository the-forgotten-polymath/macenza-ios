import SwiftUI

public struct EditCustomerSheet: View {
    public let customer: CustomerDetailModel
    public var onSaved: (CustomerDetailModel) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var pincode: String = ""
    @State private var gstin: String = ""
    @State private var creditLimit: String = ""
    @State private var paymentTerms: String = ""
    @State private var priceTier: String = ""
    @State private var passwordOverride: String = ""

    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    public init(customer: CustomerDetailModel, onSaved: @escaping (CustomerDetailModel) -> Void) {
        self.customer = customer
        self.onSaved = onSaved
        _name = State(initialValue: customer.name)
        _phone = State(initialValue: customer.phone ?? "")
        _email = State(initialValue: customer.email ?? "")
        _address = State(initialValue: customer.address ?? "")
        _city = State(initialValue: customer.city ?? "")
        _state = State(initialValue: customer.state ?? "")
        _pincode = State(initialValue: customer.pincode ?? "")
        _gstin = State(initialValue: customer.gstin ?? "")
        _creditLimit = State(initialValue: String(format: "%.0f", customer.creditLimit ?? 0))
        _paymentTerms = State(initialValue: customer.paymentTerms ?? "")
        _priceTier = State(initialValue: customer.priceTier ?? "Tier 1")
    }

    public var body: some View {
        NavigationStack {
            Form {
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.red)
                    }
                }

                Section("General Information") {
                    TextField("Customer Name", text: $name)
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                    TextField("Email", text: $email).keyboardType(.emailAddress)
                }

                Section("Address Details") {
                    TextField("Street Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("Pincode", text: $pincode).keyboardType(.numberPad)
                }

                Section("Tax & Credit Settings") {
                    TextField("GSTIN", text: $gstin).textInputAutocapitalization(.characters)
                    TextField("Credit Limit (₹)", text: $creditLimit).keyboardType(.decimalPad)
                    TextField("Payment Terms (e.g. 30 Days)", text: $paymentTerms)
                    TextField("Price Tier (e.g. Tier 1)", text: $priceTier)
                }

                Section("Account Password Override") {
                    SecureField("New Password (leave blank to keep current)", text: $passwordOverride)
                }
            }
            .navigationTitle("Edit Customer")
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

        let req = EditCustomerRequest(
            name: name,
            phone: phone,
            email: email,
            address: address,
            city: city,
            state: state,
            pincode: pincode,
            gstin: gstin,
            creditLimit: Double(creditLimit),
            paymentTerms: paymentTerms,
            priceTier: priceTier,
            password: passwordOverride.isEmpty ? nil : passwordOverride
        )

        do {
            let id = customer.id ?? customer._id ?? customer.code
            let updated = try await CustomerService.shared.updateCustomer(token: token, id: id, request: req)
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
