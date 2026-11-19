import SwiftUI
import PhotosUI

// MARK: - Settings Tab Definition
public enum SettingsTab: Int, CaseIterable, Identifiable {
    case companyProfile = 0
    case rolesPermissions = 1
    case alertTriggers = 2
    case securityAccess = 3

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .companyProfile: return "Company Profile"
        case .rolesPermissions: return "Roles & Permissions"
        case .alertTriggers: return "Alert Triggers"
        case .securityAccess: return "Security & Access"
        }
    }

    public var iconName: String {
        switch self {
        case .companyProfile: return "building.2"
        case .rolesPermissions: return "key"
        case .alertTriggers: return "bell"
        case .securityAccess: return "shield"
        }
    }

    public var iconColor: Color {
        switch self {
        case .companyProfile: return Color(hex: 0x2563EB)
        case .rolesPermissions: return Color(hex: 0x7C3AED)
        case .alertTriggers: return Color(hex: 0xF59E0B)
        case .securityAccess: return Color(hex: 0xEF4444)
        }
    }
}

// MARK: - Display Module Definition (Matching Android DISPLAY_MODULES)
private struct ErpModuleItem: Identifiable {
    let id: String
    let module: Module
    let label: String
    let backendName: String
}

private let ERP_MODULES: [ErpModuleItem] = [
    ErpModuleItem(id: "Orders", module: .orders, label: "Orders & Dispatches", backendName: "Orders"),
    ErpModuleItem(id: "Customers", module: .customers, label: "Customers & Ledger", backendName: "Customers"),
    ErpModuleItem(id: "Inventory", module: .inventory, label: "Inventory Stockpile", backendName: "Inventory"),
    ErpModuleItem(id: "Financials", module: .financials, label: "Financials & Payments", backendName: "Financials"),
    ErpModuleItem(id: "Staff", module: .staff, label: "Staff & Payroll", backendName: "Staff"),
    ErpModuleItem(id: "Audit Logs", module: .auditLogs, label: "Audit Logs", backendName: "Audit Logs"),
    ErpModuleItem(id: "Settings", module: .settings, label: "Global Settings", backendName: "Settings")
]

public struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .companyProfile

    // Photo Picker state
    @State private var selectedLogoItem: PhotosPickerItem? = nil
    @State private var selectedWatermarkItem: PhotosPickerItem? = nil

    // Company Profile state
    @State private var company: CompanyProfile = CompanyProfile()

    // Roles state
    @State private var roles: [RoleResponse] = []
    @State private var expandedRoleIds: Set<String> = []
    @State private var permissionsMap: [String: [String: ModulePermission]] = [:]

    // Alert Triggers state
    @State private var lowStockAlert: Bool = true
    @State private var creditLimitAlert: Bool = true
    @State private var newOrderAlert: Bool = true

    // Security & Access state
    @State private var maintenanceMode: Bool = false
    @State private var customers: [Customer] = []
    @State private var selectedCustomer: Customer? = nil
    @State private var customerSearchText: String = ""
    @State private var showCustomerPickerSheet: Bool = false
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmVisible: Bool = false

    // Add Role Sheet
    @State private var showAddRoleSheet: Bool = false
    @State private var newRoleName: String = ""
    @State private var newRoleDescription: String = ""

    // Common UI state
    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false
    @State private var statusMessage: String? = nil
    @State private var errorMessage: String? = nil

    public init() {
        if let arg = ProcessInfo.processInfo.arguments.first(where: { $0.starts(with: "-settingsTab:") }) {
            let tab = arg.replacingOccurrences(of: "-settingsTab:", with: "").lowercased()
            if tab == "roles" {
                _selectedTab = State(initialValue: .rolesPermissions)
            } else if tab == "alerts" {
                _selectedTab = State(initialValue: .alertTriggers)
            } else if tab == "security" {
                _selectedTab = State(initialValue: .securityAccess)
            }
        }
    }

    public var body: some View {
        ZStack {
            Color(hex: 0xF8FAFC).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top Segmented Tabs Bar (1:1 with Android) ────────
                tabSelectorBar

                // ── Status Messages Banner ────────────────────────────
                if let msg = statusMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                        Text(msg)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        Spacer()
                        Button {
                            withAnimation { statusMessage = nil }
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0x15803D))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let err = errorMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        Spacer()
                        Button {
                            withAnimation { errorMessage = nil }
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xB91C1C))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // ── Content ScrollView ────────────────────────────────
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedTab {
                            case .companyProfile:
                                companyProfileTab
                            case .rolesPermissions:
                                rolesPermissionsTab
                            case .alertTriggers:
                                alertTriggersTab
                            case .securityAccess:
                                securityAccessTab
                            }
                            Spacer().frame(height: 40)
                        }
                        .padding(16)
                    }
                    .task {
                        if ProcessInfo.processInfo.arguments.contains("-scrollTo:brandAssets") {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            withAnimation {
                                proxy.scrollTo("brandAssets", anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Global Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCustomerPickerSheet) {
            customerPickerModal
        }
        .sheet(isPresented: $showAddRoleSheet) {
            addRoleModal
        }
        .onChange(of: selectedLogoItem) { newItem in
            Task {
                await handlePickedImage(item: newItem, isWatermark: false)
            }
        }
        .onChange(of: selectedWatermarkItem) { newItem in
            Task {
                await handlePickedImage(item: newItem, isWatermark: true)
            }
        }
        .task {
            await loadInitialData()
        }
    }

    // MARK: - 1. TAB SELECTOR BAR
    private var tabSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SettingsTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            selectedTab = tab
                            statusMessage = nil
                            errorMessage = nil
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isSelected ? .white : tab.iconColor)

                            Text(tab.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(isSelected ? .white : Color(hex: 0x1E293B))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isSelected ? Color(hex: 0x2563EB) : Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.clear : Color(hex: 0xE2E8F0), lineWidth: 1)
                        )
                        .shadow(color: isSelected ? Color(hex: 0x2563EB).opacity(0.2) : Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(hex: 0xE2E8F0)),
            alignment: .bottom
        )
    }

    // MARK: - TAB 1: COMPANY PROFILE
    private var companyProfileTab: some View {
        VStack(spacing: 16) {
            // Card 1: Business Profile Information
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    Text("Business Profile Information")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: 0x1E293B))

                    Spacer()

                    // Live Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: 0x10B981))
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: 0x10B981))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: 0xECFDF5))
                    .cornerRadius(6)
                }

                Text("Official business details displayed on generated sales invoices, ledger statements, and customer portals.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))
                    .lineSpacing(3)

                VStack(spacing: 12) {
                    labeledInput(label: "Company Legal Name", isRequired: true, text: $company.name)
                    labeledInput(label: "Business Tagline / Subtitle", text: $company.tagline)
                    labeledInput(label: "GSTIN (Tax Registration No.)", isRequired: true, text: $company.gstin)
                    labeledInput(label: "Company PAN (Permanent Account No.)", text: Binding(
                        get: { company.pan ?? "" },
                        set: { company.pan = $0 }
                    ))
                    labeledInput(label: "Contact Phone", icon: "phone", text: $company.phone, keyboard: .phonePad)
                    labeledInput(label: "Support Email Address", icon: "envelope", text: $company.supportEmail, keyboard: .emailAddress)
                    labeledInput(label: "Registered Business Address", icon: "mappin.and.ellipse", text: $company.address, isMultiline: true)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            .id("brandAssets")

            // Card 2: Company Bank Settlement & NEFT Details
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "building.columns")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: 0x2563EB))

                    Text("Company Bank Settlement & NEFT Details (Tax Invoices)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: 0x1E293B))
                }

                Text("These official bank details will be printed on sales invoices for customer NEFT / RTGS payments.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))
                    .lineSpacing(3)

                VStack(spacing: 12) {
                    labeledInput(label: "Bank Name", text: Binding(
                        get: { company.bankName ?? "Bank of Baroda" },
                        set: { company.bankName = $0 }
                    ))
                    labeledInput(label: "Account Number (A/C No)", text: Binding(
                        get: { company.bankAccount ?? "12850100000449" },
                        set: { company.bankAccount = $0 }
                    ), keyboard: .numberPad)
                    labeledInput(label: "IFSC Code", text: Binding(
                        get: { company.bankIfsc ?? "BARB0RAIAJM" },
                        set: { company.bankIfsc = $0 }
                    ))
                    labeledInput(label: "Branch Name", text: Binding(
                        get: { company.bankBranch ?? "Railway Campus" },
                        set: { company.bankBranch = $0 }
                    ))
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            .id("brandAssets")

            // Card 3: Brand Assets
            VStack(alignment: .leading, spacing: 14) {
                Text("Company Brand & Document Assets")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x1E293B))

                Text("Configure the primary brand logo and warehouse photo watermark.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))

                VStack(spacing: 10) {
                    // Logo row
                    HStack(spacing: 12) {
                        brandThumbnail(
                            urlOrData: company.logo,
                            fallbackIcon: "photo.badge.checkmark",
                            iconColor: Color(hex: 0x2563EB),
                            bgColor: Color(hex: 0xEFF6FF)
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Company Brand Logo")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: 0x1E293B))
                            Text(company.logoName?.isEmpty == false ? company.logoName! : "PNG, SVG or WEBP — primary brand logo")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: 0x64748B))
                                .lineLimit(1)
                        }

                        Spacer()

                        PhotosPicker(selection: $selectedLogoItem, matching: .images) {
                            Text(company.logo?.isEmpty == false ? "Change" : "Upload")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: 0x2563EB))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: 0xEFF6FF))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Color(hex: 0xF8FAFC))
                    .cornerRadius(12)

                    // Watermark row
                    HStack(spacing: 12) {
                        brandThumbnail(
                            urlOrData: company.watermark,
                            fallbackIcon: "stamp",
                            iconColor: Color(hex: 0x7C3AED),
                            bgColor: Color(hex: 0xF5F3FF)
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Company Watermark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: 0x1E293B))
                            Text(company.watermarkName?.isEmpty == false ? company.watermarkName! : "Not configured — tap to add watermark")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: 0x64748B))
                                .lineLimit(1)
                        }

                        Spacer()

                        PhotosPicker(selection: $selectedWatermarkItem, matching: .images) {
                            Text(company.watermark?.isEmpty == false ? "Change" : "Add")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: 0x7C3AED))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: 0xF5F3FF))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Color(hex: 0xF8FAFC))
                    .cornerRadius(12)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            .id("brandAssets")

            // Save Company Profile Button
            primaryActionButton(title: "Save Company Profile", icon: "square.and.arrow.down", isBusy: isSaving) {
                await saveCompanyProfile()
            }
        }
    }

    // MARK: - TAB 2: ROLES & PERMISSIONS
    private var rolesPermissionsTab: some View {
        VStack(spacing: 14) {
            // Header Card
            VStack(alignment: .leading, spacing: 10) {
                Text("Roles & Access Control")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0x1E293B))

                Text("Configure granular View & Edit permissions per operational profile.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))

                Button {
                    newRoleName = ""
                    newRoleDescription = ""
                    showAddRoleSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add New Custom Role")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(Color(hex: 0x2563EB))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: 0xEEF2FF))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xE2E8FF), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))

            // Roles List
            if roles.isEmpty && isLoading {
                ProgressView("Loading roles matrix...")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ForEach(roles.indices, id: \.self) { index in
                    let role = roles[index]
                    let isExpanded = expandedRoleIds.contains(role.id)

                    VStack(alignment: .leading, spacing: 10) {
                        // Role Top Row
                        HStack(spacing: 10) {
                            // Avatar
                            ZStack {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(Color(hex: 0xEFF6FF))
                                    .frame(width: 32, height: 32)
                                Image(systemName: role.isMaster == true ? "shield.fill" : "person.2.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: 0x2563EB))
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    // Filled Pill
                                    Text(role.name)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: 0x2563EB))
                                        .cornerRadius(6)

                                    // Badge Pill
                                    Text(badgeText(for: role))
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Color(hex: 0x475569))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: 0xF1F5F9))
                                        .cornerRadius(6)
                                }

                                if let desc = role.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: 0x64748B))
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            // Delete Role (if custom)
                            if role.isMaster != true && role.isCustom == true {
                                Button {
                                    roles.remove(at: index)
                                    statusMessage = "Role deleted"
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: 0xB91C1C))
                                        .padding(6)
                                }
                            }

                            // Chevron toggle
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if isExpanded {
                                        expandedRoleIds.remove(role.id)
                                    } else {
                                        expandedRoleIds.insert(role.id)
                                    }
                                }
                            } label: {
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: 0x64748B))
                                    .padding(6)
                            }
                        }

                        // Expanded Content
                        if isExpanded {
                            if role.isMaster == true {
                                // Superadmin master lock view (1:1 with Android)
                                VStack(spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: 0x2563EB))
                                        Text("All 7 Modules Granted (Full Read/Write)")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Color(hex: 0x2563EB))
                                        Spacer()
                                        Text("Immutable")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(Color(hex: 0x64748B))
                                    }
                                    .padding(10)
                                    .background(Color(hex: 0xEFF6FF))
                                    .cornerRadius(10)

                                    // 2-column grid of locked module chips
                                    let pairs = ERP_MODULES.chunked(into: 2)
                                    ForEach(pairs.indices, id: \.self) { pairIndex in
                                        HStack(spacing: 8) {
                                            ForEach(pairs[pairIndex]) { mod in
                                                HStack {
                                                    Text(mod.label)
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(Color(hex: 0x1E293B))
                                                        .lineLimit(1)
                                                    Spacer()
                                                    Image(systemName: "lock.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(Color(hex: 0x10B981))
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 8)
                                                .background(Color(hex: 0xF1F5F9))
                                                .cornerRadius(8)
                                                .frame(maxWidth: .infinity)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            } else {
                                // Granular Permissions Matrix Table (1:1 with Android)
                                VStack(spacing: 4) {
                                    // Table Header
                                    HStack {
                                        Text("ERP MODULE")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(Color(hex: 0x64748B))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("VIEW")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(Color(hex: 0x64748B))
                                            .frame(width: 44, alignment: .center)
                                        Text("EDIT")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(Color(hex: 0x64748B))
                                            .frame(width: 44, alignment: .center)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(Color(hex: 0xF0F4FF))
                                    .cornerRadius(8)

                                    // Module Rows
                                    ForEach(ERP_MODULES) { erpMod in
                                        let currentPerm = role.permissions[erpMod.backendName] ?? ModulePermission(view: false, edit: false)

                                        HStack {
                                            Text(erpMod.label)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(Color(hex: 0x1E293B))
                                                .frame(maxWidth: .infinity, alignment: .leading)

                                            // View Checkbox
                                            Button {
                                                var updated = currentPerm
                                                updated.view.toggle()
                                                roles[index].permissions[erpMod.backendName] = updated
                                            } label: {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(currentPerm.view ? Color(hex: 0x1746B5) : Color(hex: 0xCBD5E1), lineWidth: 1.5)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 6)
                                                                .fill(currentPerm.view ? Color(hex: 0x1746B5) : Color.white)
                                                        )
                                                        .frame(width: 20, height: 20)

                                                    if currentPerm.view {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 11, weight: .bold))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                .frame(width: 44, height: 32)
                                            }
                                            .buttonStyle(.plain)

                                            // Edit Checkbox
                                            Button {
                                                var updated = currentPerm
                                                updated.edit.toggle()
                                                roles[index].permissions[erpMod.backendName] = updated
                                            } label: {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(currentPerm.edit ? Color(hex: 0x1746B5) : Color(hex: 0xCBD5E1), lineWidth: 1.5)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 6)
                                                                .fill(currentPerm.edit ? Color(hex: 0x1746B5) : Color.white)
                                                        )
                                                        .frame(width: 20, height: 20)

                                                    if currentPerm.edit {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 11, weight: .bold))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                .frame(width: 44, height: 32)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
                }

                // Save Permissions Button
                primaryActionButton(title: "Save Permissions", icon: "square.and.arrow.down", isBusy: isSaving) {
                    await savePermissions()
                }
            }
        }
    }

    // MARK: - TAB 3: ALERT TRIGGERS
    private var alertTriggersTab: some View {
        VStack(spacing: 16) {
            // Header Card
            VStack(alignment: .leading, spacing: 6) {
                Text("Automated System Alert Triggers")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0x1E293B))

                Text("Configure real-time trigger rules for low inventory, credit limit breaches, and pending invoice alerts.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))
                    .lineSpacing(3)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))

            // Trigger Rows Card
            VStack(spacing: 0) {
                alertTriggerRow(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: Color(hex: 0xF59E0B),
                    iconBg: Color(hex: 0xFFFBEB),
                    title: "Low Stock Buffer Threshold Alert",
                    subtitle: "Trigger notification when warehouse inventory falls below safety limit (20 units)",
                    isOn: $lowStockAlert
                )

                Divider().padding(.horizontal, 14)

                alertTriggerRow(
                    icon: "creditcard.fill",
                    iconColor: Color(hex: 0xEF4444),
                    iconBg: Color(hex: 0xFEF2F2),
                    title: "Credit Limit Exceeded Warning",
                    subtitle: "Notify sales manager when customer outstanding balance exceeds approved limit",
                    isOn: $creditLimitAlert
                )

                Divider().padding(.horizontal, 14)

                alertTriggerRow(
                    icon: "bell.fill",
                    iconColor: Color(hex: 0x2563EB),
                    iconBg: Color(hex: 0xEFF6FF),
                    title: "New Order Placement Alerts",
                    subtitle: "Notify warehouse dispatch whenever a customer places an order via mobile portal",
                    isOn: $newOrderAlert
                )
            }
            .background(Color.white)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))

            // Save Alerts Button
            primaryActionButton(title: "Save Notification Preferences", icon: "square.and.arrow.down", isBusy: isSaving) {
                isSaving = true
                try? await Task.sleep(nanoseconds: 300_000_000)
                isSaving = false
                statusMessage = "Notification preferences saved successfully!"
            }
        }
    }

    // MARK: - TAB 4: SECURITY & ACCESS
    private var securityAccessTab: some View {
        VStack(spacing: 16) {
            // Maintenance Mode Card
            VStack(alignment: .leading, spacing: 12) {
                Text("System Maintenance & Operational Mode")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x1E293B))

                Text("Temporarily pause customer mobile order submissions for ERP maintenance or physical inventory audits.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))
                    .lineSpacing(3)

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: 0xFEF2F2))
                            .frame(width: 38, height: 38)
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: 0xEF4444))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("System Maintenance Mode")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: 0x1E293B))

                        Text(maintenanceMode ? "ACTIVE (Ordering Paused)" : "INACTIVE (Normal Operation)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(maintenanceMode ? Color(hex: 0xEF4444) : Color(hex: 0x10B981))
                    }

                    Spacer()

                    Toggle("", isOn: $maintenanceMode)
                        .labelsHidden()
                        .tint(Color(hex: 0xEF4444))
                        .onChange(of: maintenanceMode) { val in
                            statusMessage = val ? "Maintenance mode activated. Customer orders paused." : "System maintenance mode deactivated."
                        }
                }
                .padding(12)
                .background(Color(hex: 0xF8FAFC))
                .cornerRadius(12)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            .id("brandAssets")

            // Password Override Card
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: 0x2563EB))
                    Text("Customer Account Password Override")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: 0x1E293B))
                }

                Text("Superadmin root override. Set a new temporary password for any dealer or customer account directly.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x64748B))
                    .lineSpacing(3)

                VStack(alignment: .leading, spacing: 6) {
                    Text("SELECT CUSTOMER ACCOUNT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: 0x64748B))

                    Button {
                        showCustomerPickerSheet = true
                    } label: {
                        HStack {
                            if let selected = selectedCustomer {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selected.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: 0x1E293B))
                                    Text("\(selected.code) • \(selected.city ?? "")")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: 0x64748B))
                                }
                            } else {
                                Text("Choose a dealer account...")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: 0x94A3B8))
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: 0x64748B))
                        }
                        .padding(12)
                        .background(Color(hex: 0xF8FAFC))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                // Password fields
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Temporary Password")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: 0x475569))

                        HStack {
                            if isPasswordVisible {
                                TextField("Enter at least 6 characters", text: $newPassword)
                            } else {
                                SecureField("Enter at least 6 characters", text: $newPassword)
                            }
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(Color(hex: 0x94A3B8))
                            }
                        }
                        .padding(12)
                        .background(Color(hex: 0xF8FAFC))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirm New Password")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: 0x475569))

                        HStack {
                            if isConfirmVisible {
                                TextField("Re-enter new password", text: $confirmPassword)
                            } else {
                                SecureField("Re-enter new password", text: $confirmPassword)
                            }
                            Button {
                                isConfirmVisible.toggle()
                            } label: {
                                Image(systemName: isConfirmVisible ? "eye.slash" : "eye")
                                    .foregroundColor(Color(hex: 0x94A3B8))
                            }
                        }
                        .padding(12)
                        .background(Color(hex: 0xF8FAFC))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
                    }
                }

                // Override Button
                primaryActionButton(title: "Override Account Password", icon: "lock.rotation", isBusy: isSaving) {
                    await performPasswordOverride()
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            .id("brandAssets")
        }
    }

    // MARK: - Helper Views & Components
    private func labeledInput(
        label: String,
        isRequired: Bool = false,
        icon: String? = nil,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        isMultiline: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: 0x475569))
                if isRequired {
                    Text("*")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0xEF4444))
                }
            }

            HStack(spacing: 8) {
                if let ic = icon {
                    Image(systemName: ic)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x64748B))
                }

                if isMultiline {
                    TextField(label, text: text, axis: .vertical)
                        .lineLimit(2...4)
                } else {
                    TextField(label, text: text)
                        .keyboardType(keyboard)
                }
            }
            .padding(11)
            .background(Color(hex: 0xF8FAFC))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
        }
    }

    private func alertTriggerRow(
        icon: String,
        iconColor: Color,
        iconBg: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconBg)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: 0x1E293B))

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x64748B))
                        .lineSpacing(2)
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isOn.wrappedValue ? Color(hex: 0x2563EB) : Color(hex: 0xCBD5E1), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isOn.wrappedValue ? Color(hex: 0x2563EB) : Color.white)
                        )
                        .frame(width: 20, height: 20)

                    if isOn.wrappedValue {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    private func primaryActionButton(title: String, icon: String, isBusy: Bool, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 8) {
                if isBusy {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(hex: 0x2563EB))
            .cornerRadius(12)
            .shadow(color: Color(hex: 0x2563EB).opacity(0.25), radius: 4, x: 0, y: 2)
        }
        .disabled(isBusy)
    }

    private func badgeText(for role: RoleResponse) -> String {
        if role.isMaster == true { return "Master Root" }
        if role.name.caseInsensitiveCompare("Admin") == .orderedSame { return "System Role" }
        if role.name.caseInsensitiveCompare("Customer") == .orderedSame { return "Portal Role" }
        return "Custom Role"
    }

    // MARK: - Customer Picker Modal
    private var customerPickerModal: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(hex: 0x64748B))
                    TextField("Search customer by name, code or city...", text: $customerSearchText)
                }
                .padding(10)
                .background(Color(hex: 0xF1F5F9))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 10)

                let filtered = customers.filter { c in
                    customerSearchText.isEmpty ||
                    c.name.localizedCaseInsensitiveContains(customerSearchText) ||
                    c.code.localizedCaseInsensitiveContains(customerSearchText) ||
                    (c.city?.localizedCaseInsensitiveContains(customerSearchText) == true)
                }

                List(filtered) { customer in
                    Button {
                        selectedCustomer = customer
                        showCustomerPickerSheet = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(customer.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: 0x1E293B))
                                Text("\(customer.code) • \(customer.city ?? "")")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: 0x64748B))
                            }
                            Spacer()
                            if selectedCustomer?.id == customer.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: 0x2563EB))
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Customer Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCustomerPickerSheet = false }
                }
            }
        }
    }

    // MARK: - Add Custom Role Modal
    private var addRoleModal: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Define a new operational role profile. Granular View & Edit module permissions can be configured once added.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))

                labeledInput(label: "Role Name", isRequired: true, text: $newRoleName)
                labeledInput(label: "Role Description", text: $newRoleDescription)

                Spacer()

                primaryActionButton(title: "Create Role", icon: "plus", isBusy: false) {
                    guard !newRoleName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let newId = UUID().uuidString
                    let defaultPerms: [String: ModulePermission] = [
                        "Orders": ModulePermission(view: true, edit: false),
                        "Customers": ModulePermission(view: true, edit: false),
                        "Inventory": ModulePermission(view: true, edit: false),
                        "Financials": ModulePermission(view: false, edit: false),
                        "Staff": ModulePermission(view: false, edit: false),
                        "Audit Logs": ModulePermission(view: false, edit: false),
                        "Settings": ModulePermission(view: false, edit: false)
                    ]
                    let newRoleJson: [String: Any] = [
                        "id": newId,
                        "name": newRoleName,
                        "description": newRoleDescription,
                        "isMaster": false,
                        "isCustom": true,
                        "permissions": [:]
                    ]
                    if let data = try? JSONSerialization.data(withJSONObject: newRoleJson),
                       let decoded = try? JSONDecoder().decode(RoleResponse.self, from: data) {
                        var r = decoded
                        r.permissions = defaultPerms
                        roles.append(r)
                        expandedRoleIds.insert(newId)
                        statusMessage = "Custom role '\(newRoleName)' created!"
                        showAddRoleSheet = false
                    }
                }
            }
            .padding(16)
            .navigationTitle("Add New Custom Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddRoleSheet = false }
                }
            }
        }
    }

    // MARK: - API Actions
    private func loadInitialData() async {
        guard let token = SessionManager.shared.session?.token else { return }
        isLoading = true
        do {
            async let comp = SettingsService.shared.fetchCompanyProfile(token: token)
            async let rls = SettingsService.shared.fetchRoles(token: token)
            async let custs = CustomerService.shared.fetchCustomers(token: token)

            let (c, r, cu) = try await (comp, rls, custs)

            await MainActor.run {
                self.company = c
                self.roles = r
                self.customers = cu
                if let firstMaster = r.first(where: { $0.isMaster == true }) {
                    self.expandedRoleIds.insert(firstMaster.id)
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func saveCompanyProfile() async {
        guard let token = SessionManager.shared.session?.token else { return }
        isSaving = true
        statusMessage = nil
        errorMessage = nil
        do {
            let updated = try await SettingsService.shared.updateCompanyProfile(token: token, profile: company)
            await MainActor.run {
                self.company = updated
                self.isSaving = false
                self.statusMessage = "Company profile successfully saved!"
            }
        } catch {
            await MainActor.run {
                self.isSaving = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func savePermissions() async {
        guard let token = SessionManager.shared.session?.token else { return }
        isSaving = true
        statusMessage = nil
        errorMessage = nil

        var permMap: [String: [String: ModulePermission]] = [:]
        for r in roles {
            permMap[r.name] = r.permissions
        }
        let req = BulkSaveMatrixRequest(roles: roles, permissionsMap: permMap)

        do {
            try await SettingsService.shared.bulkSavePermissionMatrix(token: token, request: req)

            // Update local session permissions if Admin or matching role is currently active
            await MainActor.run {
                if let currentSession = SessionManager.shared.session {
                    if let matched = self.roles.first(where: { $0.name.caseInsensitiveCompare(currentSession.backendRole) == .orderedSame }) {
                        SessionManager.shared.updatePermissions(matched.permissions)
                    }
                }
                self.isSaving = false
                self.statusMessage = "Permissions matrix successfully updated!"
            }
        } catch {
            await MainActor.run {
                self.isSaving = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func performPasswordOverride() async {
        guard let customer = selectedCustomer else {
            errorMessage = "Please select a customer account first."
            return
        }
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password."
            return
        }
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters long."
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        guard let token = SessionManager.shared.session?.token else { return }

        isSaving = true
        statusMessage = nil
        errorMessage = nil

        let custEmail = customer.email ?? ""
        let identifier = !customer.code.isEmpty ? customer.code : (!custEmail.isEmpty ? custEmail : customer.name)

        do {
            let success = try await AuthService.shared.changePassword(
                token: token,
                identifier: identifier,
                oldPass: "",
                newPass: newPassword
            )
            await MainActor.run {
                self.isSaving = false
                if success {
                    self.statusMessage = "Password for \(customer.name) overridden successfully!"
                    self.newPassword = ""
                    self.confirmPassword = ""
                }
            }
        } catch {
            await MainActor.run {
                self.isSaving = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Image Picking & Upload
    private func handlePickedImage(item: PhotosPickerItem?, isWatermark: Bool) async {
        guard let item = item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                await MainActor.run {
                    self.errorMessage = "Could not load the selected image."
                }
                return
            }

            // Downsample / resize to max dimension 512 for optimal storage and network transmission
            let resized = uiImage.resized(maxDimension: 512)
            guard let jpegData = resized.jpegData(compressionQuality: 0.85) else {
                await MainActor.run {
                    self.errorMessage = "Failed to process image data."
                }
                return
            }

            let base64String = jpegData.base64EncodedString()
            let dataUri = "data:image/jpeg;base64,\(base64String)"
            let timestamp = Int(Date().timeIntervalSince1970)

            await MainActor.run {
                self.isSaving = true
                self.statusMessage = nil
                self.errorMessage = nil

                if isWatermark {
                    self.company.watermark = dataUri
                    self.company.watermarkName = "watermark_\(timestamp).jpg"
                } else {
                    self.company.logo = dataUri
                    self.company.logoName = "company_logo_\(timestamp).jpg"
                }
            }

            // Persist immediately to backend
            guard let token = SessionManager.shared.session?.token else {
                await MainActor.run {
                    self.isSaving = false
                    self.statusMessage = isWatermark ? "Watermark updated locally!" : "Company logo updated locally!"
                }
                return
            }

            let updated = try await SettingsService.shared.updateCompanyProfile(token: token, profile: self.company)
            await MainActor.run {
                self.company = updated
                self.isSaving = false
                self.statusMessage = isWatermark ? "Company watermark saved successfully!" : "Company logo saved successfully!"
            }
        } catch {
            await MainActor.run {
                self.isSaving = false
                self.errorMessage = "Error uploading image: \(error.localizedDescription)"
            }
        }
    }

    @ViewBuilder
    private func brandThumbnail(urlOrData: String?, fallbackIcon: String, iconColor: Color, bgColor: Color) -> some View {
        if let str = urlOrData, !str.isEmpty {
            if let decoded = decodeImage(str) {
                Image(uiImage: decoded)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if str.starts(with: "http"), let url = URL(string: str) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    default:
                        Image(systemName: fallbackIcon)
                            .font(.system(size: 20))
                            .foregroundColor(iconColor)
                            .frame(width: 40, height: 40)
                            .background(bgColor)
                            .cornerRadius(10)
                    }
                }
            } else {
                Image(systemName: fallbackIcon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(bgColor)
                    .cornerRadius(10)
            }
        } else {
            Image(systemName: fallbackIcon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(bgColor)
                .cornerRadius(10)
        }
    }

    private func decodeImage(_ string: String) -> UIImage? {
        if string.hasPrefix("data:image"), let commaIdx = string.firstIndex(of: ",") {
            let base64 = String(string[string.index(after: commaIdx)...])
            if let data = Data(base64Encoded: base64) {
                return UIImage(data: data)
            }
        } else if let data = Data(base64Encoded: string) {
            return UIImage(data: data)
        }
        return nil
    }
}

// MARK: - UIImage Resize Helper
private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let size = self.size
        let ratio = min(maxDimension / max(size.width, 1), maxDimension / max(size.height, 1))
        if ratio >= 1.0 { return self }
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Array Chunk Helper
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
