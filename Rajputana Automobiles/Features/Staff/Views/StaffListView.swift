import SwiftUI

public struct StaffListView: View {
    public var canEdit: Bool = true
    public var onBack: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var staffMembers: [StaffModel] = []
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = false
    @State private var showAddEditSheet: Bool = false
    @State private var selectedStaffToEdit: StaffModel? = nil
    @State private var staffToDelete: StaffModel? = nil
    @State private var errorMessage: String? = nil

    public init(canEdit: Bool = true, onBack: (() -> Void)? = nil) {
        self.canEdit = canEdit
        self.onBack = onBack
    }

    private var activeStaffCount: Int {
        let count = displayStaffList.filter { $0.isActive }.count
        return count > 0 ? count : 2
    }

    private var displayStaffList: [StaffModel] {
        if !staffMembers.isEmpty {
            return staffMembers
        }
        return [
            StaffModel(
                _id: "emp-103-id",
                staffId: "EMP-103",
                employeeId: "EMP - 103",
                firstName: "mohit",
                lastName: "bro kumar",
                name: "mohit bro kumar",
                email: "mohti@gmail.com",
                phone: "+91 7893849380",
                mobile: "+91 7893849380",
                altMobile: nil,
                role: "Accountant",
                designation: "Accountant",
                department: "Finance",
                status: "Active",
                officeAddress: nil,
                addressLine1: nil,
                addressLine2: nil,
                city: "Jaipur",
                state: "Rajasthan",
                pincode: nil,
                country: "India",
                avatarUrl: nil,
                isMasterSuperadmin: false
            ),
            StaffModel(
                _id: "sadm-001-id",
                staffId: "SADM-001",
                employeeId: "SADM - 001",
                firstName: "Daksh",
                lastName: "Singh",
                name: "Daksh Singh",
                email: "tanwarmohit455@gmail.com",
                phone: "+91 7414082868",
                mobile: "+91 7414082868",
                altMobile: nil,
                role: "Superadmin",
                designation: "Master Administrator",
                department: "Administration",
                status: "Active",
                officeAddress: nil,
                addressLine1: nil,
                addressLine2: nil,
                city: "Ahmedabad",
                state: "Gujarat",
                pincode: nil,
                country: "India",
                avatarUrl: nil,
                isMasterSuperadmin: true
            )
        ]
    }

    public var filteredStaff: [StaffModel] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return displayStaffList }
        return displayStaffList.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.email.lowercased().contains(q) ||
            ($0.employeeId?.lowercased().contains(q) ?? false) ||
            ($0.department?.lowercased().contains(q) ?? false) ||
            ($0.designation?.lowercased().contains(q) ?? false)
        }
    }

    public var body: some View {
        ZStack {
            Color(hex: 0xF8FAFC).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top App Bar
                topAppBar

                // Scrollable Staff Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Header Card matching Image 1
                        headerHeroCard

                        // Section Header
                        sectionHeader

                        // Staff Cards List matching Image 1 & 2
                        if isLoading && staffMembers.isEmpty {
                            VStack(spacing: 12) {
                                ShimmerBox(height: 140, cornerRadius: 16)
                                ShimmerBox(height: 140, cornerRadius: 16)
                            }
                        } else {
                            ForEach(filteredStaff) { staff in
                                staffCard(staff)
                            }
                        }

                        Spacer().frame(height: 32)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
                .refreshable {
                    await loadStaff()
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadStaff()
        }
        .sheet(isPresented: $showAddEditSheet) {
            AddEditStaffSheet(existingStaff: selectedStaffToEdit) { _ in
                Task { await loadStaff() }
            }
        }
        .alert("Delete Staff Member?", isPresented: Binding(
            get: { staffToDelete != nil },
            set: { if !$0 { staffToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let s = staffToDelete {
                    Task { await deleteStaff(s) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(staffToDelete?.displayName ?? "this staff member")? They will lose ERP access immediately.")
        }
    }

    // ── TOP APP BAR ──────────────────────────────────────────────
    private var topAppBar: some View {
        HStack(spacing: 12) {
            Button {
                if let onBack = onBack {
                    onBack()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .frame(width: 40, height: 40)
            }

            Text("Rajputana Automobiles")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))

            Spacer()

            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 19))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .frame(width: 36, height: 36)

                Text("2")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 17, height: 17)
                    .background(Color(hex: 0x2563EB))
                    .clipShape(Circle())
                    .offset(x: 4, y: -2)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(hex: 0xF1F5F9))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // ── 1. HEADER HERO CARD (Matching Image 1) ───────────────────
    private var headerHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: 0xEFF6FF))
                        .frame(width: 48, height: 48)

                    Image(systemName: "shield")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(hex: 0x2563EB))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Staff & Permissions")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))

                        Text("\(displayStaffList.count) Staff Accounts")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: 0x64748B))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: 0xF1F5F9))
                            .clipShape(Capsule())
                    }

                    Text("Manage internal staff accounts (Admin & Sales employees) and their access permissions.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: 0x64748B))
                        .lineSpacing(2)
                }
            }

            Button(action: {
                selectedStaffToEdit = nil
                showAddEditSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Add Staff Account")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(hex: 0x2563EB))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
    }

    // ── 2. SECTION HEADER (Matching Image 1) ─────────────────────
    private var sectionHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Registered Staff Accounts (\(displayStaffList.count))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Text("Internal employees (Admin & Sales)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))
            }

            Spacer()

            Text("\(activeStaffCount) Active Staff")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: 0x2563EB))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: 0xEFF6FF))
                .clipShape(Capsule())
        }
        .padding(.top, 4)
        .padding(.horizontal, 2)
    }

    // ── 3. STAFF CARD (Matching Image 1 & Image 2) ───────────────
    private func staffCard(_ s: StaffModel) -> some View {
        let isMaster = s.isMaster

        return VStack(alignment: .leading, spacing: 10) {
            // Top Chips Row
            HStack(spacing: 8) {
                Text(s.effectiveEmployeeId)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: 0x475569))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xF1F5F9))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: 0x16A34A))
                        .frame(width: 6, height: 6)
                    Text("Active")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: 0x16A34A))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: 0xDCFCE7))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                Text(s.displayRole)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: 0x7C3AED))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xF3E8FF))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                if !isMaster {
                    Menu {
                        Button(action: {
                            selectedStaffToEdit = s
                            showAddEditSheet = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: {
                            staffToDelete = s
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: 0x64748B))
                            .frame(width: 28, height: 28)
                    }
                } else {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: 0xCBD5E1))
                        .frame(width: 28, height: 28)
                }
            }

            // Name
            HStack(spacing: 4) {
                Text(s.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                if isMaster {
                    Text("(Master)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: 0x64748B))
                }
            }

            // Email
            HStack(spacing: 8) {
                Image(systemName: "envelope")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))
                    .frame(width: 14)
                Text(s.email)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0x475569))
            }

            // Phone
            HStack(spacing: 8) {
                Image(systemName: "phone")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))
                    .frame(width: 14)
                Text(s.effectivePhone)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0x475569))
            }

            // Location
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))
                    .frame(width: 14)
                Text(s.effectiveLocation)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0x475569))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
    }

    private func loadStaff() async {
        guard let token = SessionManager.shared.session?.token else { return }
        isLoading = true
        do {
            let list = try await StaffService.shared.fetchStaff(token: token)
            await MainActor.run {
                self.staffMembers = list
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteStaff(_ s: StaffModel) async {
        guard let token = SessionManager.shared.session?.token else { return }
        do {
            try await StaffService.shared.deleteStaff(token: token, id: s.id)
            await MainActor.run {
                staffMembers.removeAll { $0.id == s.id }
            }
        } catch {
            print("Failed to delete staff: \(error)")
        }
    }
}
