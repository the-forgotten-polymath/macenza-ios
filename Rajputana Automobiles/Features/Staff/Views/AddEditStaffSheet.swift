import SwiftUI
import PhotosUI

public struct AddEditStaffSheet: View {
    public let existingStaff: StaffModel?
    public var onSaved: (StaffModel) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var employeeId: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var role: String = "admin"
    @State private var designation: String = ""
    @State private var department: String = "Operations"
    @State private var officeAddress: String = ""
    @State private var selectedState: String = "Rajasthan"
    @State private var selectedDistrict: String = "Jaipur"
    @State private var pincode: String = ""
    @State private var status: String = "Active"
    @State private var avatarUrl: String = ""

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isUploadingAvatar: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    private let rolesList = ["admin", "manager", "staff"]
    private let departmentList = ["Operations", "Warehouse", "Sales", "Finance", "Administration"]

    public init(existingStaff: StaffModel? = nil, onSaved: @escaping (StaffModel) -> Void) {
        self.existingStaff = existingStaff
        self.onSaved = onSaved

        if let s = existingStaff {
            _employeeId = State(initialValue: s.employeeId ?? "")
            _name = State(initialValue: s.displayName)
            _email = State(initialValue: s.email ?? "")
            _phone = State(initialValue: s.phone ?? "")
            _role = State(initialValue: s.role ?? "admin")
            _designation = State(initialValue: s.designation ?? "")
            _department = State(initialValue: s.department ?? "Operations")
            _officeAddress = State(initialValue: s.officeAddress ?? "")
            _selectedState = State(initialValue: s.state ?? "Rajasthan")
            _selectedDistrict = State(initialValue: s.city ?? "Jaipur")
            _pincode = State(initialValue: s.pincode ?? "")
            _status = State(initialValue: s.status ?? "Active")
            _avatarUrl = State(initialValue: s.avatarUrl ?? "")
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                if let err = errorMessage {
                    Section {
                        Text(err).font(AppTypography.caption).foregroundColor(AppColors.red)
                    }
                }

                Section("Avatar Photo") {
                    HStack(spacing: 16) {
                        ZStack(alignment: .bottomTrailing) {
                            if !avatarUrl.isEmpty {
                                RemoteImageView(urlString: avatarUrl, contentMode: .fill)
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(LiquidTheme.electricBlue)
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Text(initials(name.isEmpty ? "ST" : name))
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }

                            if isUploadingAvatar {
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 64, height: 64)
                                    .overlay(ProgressView().tint(.white))
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                    Text(avatarUrl.isEmpty ? "Upload Photo" : "Change Photo")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(LiquidTheme.electricBlue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: 0xEFF6FF))
                                .clipShape(Capsule())
                            }
                            .disabled(isUploadingAvatar)

                            Text("JPG or PNG under 5 MB")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: 0x94A3B8))
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Employee Profile") {
                    TextField("Employee ID (e.g. EMP-101)", text: $employeeId)
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email).keyboardType(.emailAddress).autocorrectionDisabled().textInputAutocapitalization(.never)
                    TextField("Phone Number", text: $phone).keyboardType(.phonePad)
                }

                Section("Role & Assignment") {
                    Picker("Role", selection: $role) {
                        ForEach(rolesList, id: \.self) { r in
                            Text(r.capitalized).tag(r)
                        }
                    }

                    Picker("Department", selection: $department) {
                        ForEach(departmentList, id: \.self) { d in
                            Text(d).tag(d)
                        }
                    }

                    TextField("Designation (e.g. Inventory Manager)", text: $designation)

                    Picker("Account Status", selection: $status) {
                        Text("Active").tag("Active")
                        Text("Inactive").tag("Inactive")
                    }
                }

                Section("Office Address & Location") {
                    TextField("Office Address", text: $officeAddress)

                    Picker("State", selection: $selectedState) {
                        ForEach(DistrictDataLoader.shared.states, id: \.self) { st in
                            Text(st).tag(st)
                        }
                    }
                    .onChange(of: selectedState) { _, newState in
                        if let firstCity = DistrictDataLoader.shared.districts(for: newState).first {
                            selectedDistrict = firstCity
                        }
                    }

                    Picker("City / District", selection: $selectedDistrict) {
                        ForEach(DistrictDataLoader.shared.districts(for: selectedState), id: \.self) { dist in
                            Text(dist).tag(dist)
                        }
                    }

                    TextField("Pincode", text: $pincode).keyboardType(.numberPad)
                }
            }
            .navigationTitle(existingStaff == nil ? "New Staff Account" : "Edit Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveStaff() }
                    }
                    .disabled(isSaving || name.isEmpty || email.isEmpty)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        await uploadAvatar(data: data)
                    }
                }
            }
        }
    }

    private func uploadAvatar(data: Data) async {
        guard let token = SessionManager.shared.session?.token else { return }
        isUploadingAvatar = true
        errorMessage = nil

        let base64 = data.base64EncodedString()
        let dataUri = "data:image/jpeg;base64,\(base64)"

        do {
            let uploaded = try await StaffService.shared.uploadAvatar(
                token: token,
                email: email.isEmpty ? (SessionManager.shared.session?.email ?? "") : email,
                role: role,
                imageBase64DataUri: dataUri,
                identifier: employeeId.isEmpty ? nil : employeeId
            )
            await MainActor.run {
                self.isUploadingAvatar = false
                self.avatarUrl = uploaded
            }
        } catch {
            await MainActor.run {
                self.isUploadingAvatar = false
                self.errorMessage = "Failed to upload photo: \(error.localizedDescription)"
            }
        }
    }

    private func saveStaff() async {
        guard let token = SessionManager.shared.session?.token else { return }
        isSaving = true
        errorMessage = nil

        let req = StaffRequest(
            employeeId: employeeId.isEmpty ? nil : employeeId,
            name: name,
            email: email,
            phone: phone,
            role: role,
            designation: designation,
            department: department,
            status: status,
            officeAddress: officeAddress,
            city: selectedDistrict,
            state: selectedState,
            pincode: pincode
        )

        do {
            let result: StaffModel
            if let existing = existingStaff {
                result = try await StaffService.shared.updateStaff(token: token, id: existing.id, request: req)
            } else {
                result = try await StaffService.shared.createStaff(token: token, request: req)
            }

            await MainActor.run {
                isSaving = false
                onSaved(result)
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
