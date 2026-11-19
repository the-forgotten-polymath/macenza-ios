import SwiftUI
import PhotosUI

public struct UserProfileView: View {
    // ── External Navigation & Embedding Hooks ──────────────────
    public var showsTopBar: Bool = false
    public var showsBottomBar: Bool = false
    public var onOpenDrawer: (() -> Void)? = nil
    public var onOpenNotifications: (() -> Void)? = nil
    public var onSignOut: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    // ── Profile Fields ─────────────────────────────────────────
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var gstin: String = ""
    @State private var address: String = ""
    @State private var country: String = "India"
    @State private var state: String = "Maharashtra"
    @State private var city: String = "Punee"
    @State private var pincode: String = "411026"
    @State private var designation: String = ""
    @State private var department: String = ""
    @State private var employeeId: String = ""
    @State private var avatarUrl: String = ""
    @State private var tallyLedgerName: String = ""
    @State private var priceTier: String = ""
    @State private var paymentTerms: String = ""
    @State private var creditLimit: Double = 0.0
    @State private var outstandingBalance: Double = 0.0

    // ── Edit Mode & Dirty Tracking ─────────────────────────────
    @State private var isEditing: Bool = false
    @State private var isSaving: Bool = false

    // Initial snapshot for dirty tracking and cancel reset
    @State private var initialName: String = ""
    @State private var initialPhone: String = ""
    @State private var initialEmail: String = ""
    @State private var initialGstin: String = ""
    @State private var initialAddress: String = ""
    @State private var initialCountry: String = "India"
    @State private var initialState: String = "Maharashtra"
    @State private var initialCity: String = "Punee"
    @State private var initialPincode: String = "411026"
    @State private var initialDesignation: String = ""
    @State private var initialDepartment: String = ""

    // ── Photo Source Sheet & Camera State ──────────────────────
    @State private var showImageSourceSheet: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showCamera: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isUploadingAvatar: Bool = false

    // ── Change Password State ──────────────────────────────────
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showCurrentPass: Bool = false
    @State private var showNewPass: Bool = false
    @State private var showConfirmPass: Bool = false
    @State private var isChangingPassword: Bool = false
    @State private var passwordMessage: String? = nil
    @State private var passwordError: String? = nil

    // ── Dialogs & Toast ────────────────────────────────────────
    @State private var showSignOutAlert: Bool = false
    @State private var toastMessage: String? = nil

    // Support Desk Details (for Customer role)
    private let supportPhoneDisplay = "+91 80033 12345"
    private let supportPhoneDial = "tel:+918003312345"
    private let supportEmail = "mailto:rajputanaautomobilesjaipur@gmail.com"
    private let supportWhatsApp = "https://wa.me/918003312345?text=Hello%20Rajputana%20Automobiles%20Support"

    public init(
        showsTopBar: Bool = false,
        showsBottomBar: Bool = false,
        onOpenDrawer: (() -> Void)? = nil,
        onOpenNotifications: (() -> Void)? = nil,
        onSignOut: (() -> Void)? = nil
    ) {
        self.showsTopBar = showsTopBar
        self.showsBottomBar = showsBottomBar
        self.onOpenDrawer = onOpenDrawer
        self.onOpenNotifications = onOpenNotifications
        self.onSignOut = onSignOut
    }

    private var session: AuthSession? {
        SessionManager.shared.session
    }

    private var isCustomer: Bool {
        session?.role == .customer
    }

    private var isSuperAdmin: Bool {
        session?.role == .superadmin
    }

    private var roleLabel: String {
        guard let s = session else { return "Administrator" }
        switch s.role {
        case .superadmin:
            return "Superadmin"
        case .admin:
            let raw = s.backendRole.trimmingCharacters(in: .whitespacesAndNewlines)
            if raw.isEmpty || raw.lowercased() == "admin" {
                return "Administrator"
            }
            return raw.capitalized
        case .customer:
            return "Customer / Dealer"
        }
    }

    private var userInitials: String {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.isEmpty { return "R" }
        let parts = n.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            let first = parts[0].prefix(1).uppercased()
            let second = parts[1].prefix(1).uppercased()
            return "\(first)\(second)"
        }
        return String(n.prefix(1)).uppercased()
    }

    private var availableStates: [String] {
        let loaded = DistrictDataLoader.shared.states
        if loaded.isEmpty {
            return ["Maharashtra", "Rajasthan", "Gujarat", "Delhi", "Madhya Pradesh", "Karnataka", "Uttar Pradesh", "Punjab", "Haryana", "Tamil Nadu"]
        }
        return loaded
    }

    private var availableDistricts: [String] {
        let loaded = DistrictDataLoader.shared.districts(for: state)
        if loaded.isEmpty {
            if state.caseInsensitiveCompare("Maharashtra") == .orderedSame {
                return ["Punee", "Pune", "Mumbai", "Nagpur", "Nashik", "Thane", "Aurangabad"]
            } else if state.caseInsensitiveCompare("Rajasthan") == .orderedSame {
                return ["Jaipur", "Ajmer", "Bhilwara", "Beawar", "Jodhpur", "Kota", "Udaipur", "Bikaner"]
            }
            return [city]
        }
        return loaded
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Optional standalone Top Bar
                if showsTopBar {
                    standaloneTopBar
                }

                // Scrollable Profile Dossier
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            // ── 1. HEADER AVATAR & IDENTITY HERO CARD ────────
                            heroIdentityCard
                                .id("heroCard")

                            // ── 2. PERSONAL & OFFICE / BUSINESS DETAILS ─────
                            personalAndOfficeDetailsCard
                                .id("detailsCard")

                            // ── 3. ACCOUNT & CREDIT STANDING (Customer Only) ─
                            if isCustomer {
                                customerAccountDetailsCard
                                    .id("accountDetailsCard")
                            }

                            // ── 4. CHANGE ACCOUNT PASSWORD ──────────────────
                            changePasswordCard
                                .id("passwordCard")

                            // ── 5. DEALER ASSISTANCE & SUPPORT (Customer Only)
                            if isCustomer {
                                supportHotlineCard
                                    .id("supportCard")
                            }

                            // ── 6. SIGN OUT OF ACCOUNT ──────────────────────
                            signOutCard
                                .id("signOutCard")

                            Spacer(minLength: 50)
                                .id("bottomSpacer")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    .background(Color(hex: 0xF8FAFC))
                    .onAppear {
                        if ProcessInfo.processInfo.arguments.contains("-editMode") {
                            startEditing()
                        }
                        if ProcessInfo.processInfo.arguments.contains("-showPhotoSheet") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showImageSourceSheet = true
                                }
                            }
                        } else if ProcessInfo.processInfo.arguments.contains("-openCamera") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showCamera = true
                            }
                        }
                        if ProcessInfo.processInfo.arguments.contains("-scroll:bottom") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    proxy.scrollTo("bottomSpacer", anchor: .bottom)
                                }
                            }
                        } else if ProcessInfo.processInfo.arguments.contains("-scroll:middle") || ProcessInfo.processInfo.arguments.contains("-scroll:password") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    proxy.scrollTo("passwordCard", anchor: .top)
                                }
                            }
                        }
                    }
                }

                // Optional standalone Bottom Bar
                if showsBottomBar {
                    standaloneBottomBar
                }
            }

            // ── DIMMED SCRIM & MODAL BOTTOM SHEET (Take Photo vs Gallery) ──
            if showImageSourceSheet {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showImageSourceSheet = false
                        }
                    }
                    .transition(.opacity)

                VStack(spacing: 0) {
                    Spacer()

                    imageSourceBottomSheet
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .ignoresSafeArea(edges: .bottom)
                .zIndex(99)
            }

            // ── FULL SCREEN CAMERA VIEWFINDER OVERLAY ───────────────────
            if showCamera {
                ProfileCameraView(
                    onImageCaptured: { capturedImage in
                        withAnimation { showCamera = false }
                        Task { await processAndUploadImage(capturedImage) }
                    },
                    onDismiss: {
                        withAnimation { showCamera = false }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .background(Color(hex: 0xF8FAFC).ignoresSafeArea())
        .task {
            await loadProfile()
        }
        // Native System Gallery Picker
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            if let item = newItem {
                Task { await handlePhotoPicked(item) }
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                SessionManager.shared.signOut()
                onSignOut?()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to disconnect your active session on this device?")
        }
        .overlay(alignment: .bottom) {
            if let toast = toastMessage {
                Text(toast)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 26)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // ============================================================
    // 1. HERO IDENTITY CARD (Matching Android 1:1)
    // ============================================================
    private var heroIdentityCard: some View {
        HStack(spacing: 12) {
            // Circular Avatar (65dp) with Click-to-Open Source Sheet
            Button {
                showImageSourceSheet = true
            } label: {
                ZStack {
                    if !avatarUrl.isEmpty {
                        RemoteImageView(
                            urlString: avatarUrl,
                            contentMode: .fill,
                            placeholderIcon: "person.fill",
                            height: 65,
                            cornerRadius: 32.5
                        )
                        .frame(width: 65, height: 65)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(hex: 0x4C68F5), Color(hex: 0x2453E8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 65, height: 65)
                            .overlay(
                                Text(userInitials)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(Color.white)
                            )
                    }

                    if isUploadingAvatar {
                        Circle()
                            .fill(Color.black.opacity(0.45))
                            .frame(width: 65, height: 65)
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                            )
                    }
                }
            }
            .buttonStyle(.plain)

            // Name, Purple Role, and Subtitle
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(name.isEmpty ? (session?.name ?? "Rajputana") : name)
                        .font(.system(size: 16.5, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0F172A))
                        .lineLimit(1)

                    Text(roleLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x7C3AED)) // Purple
                        .lineLimit(1)
                }

                let sub = isCustomer
                    ? (tallyLedgerName.isEmpty ? (session?.customerCode ?? "Dealer Account") : tallyLedgerName)
                    : (designation.isEmpty ? (isSuperAdmin ? "Managing Director & Chief Executive Officer" : "Operations & Fleet Manager") : designation)

                Text(sub)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(hex: 0x64748B))
                    .lineLimit(2)
                    .lineSpacing(2)
            }

            Spacer()

            // Circular Pencil Edit Button (45dp, light blue bg)
            Button {
                showImageSourceSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: 0xEFF6FF))
                        .frame(width: 45, height: 45)

                    Image(systemName: "pencil")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x2563EB))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ============================================================
    // IMAGE SOURCE BOTTOM SHEET (1:1 with Android ImageSourceBottomSheet)
    // ============================================================
    private var imageSourceBottomSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add Profile Photo")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: 0x0F172A))
                .padding(.top, 20)

            Text("Take a photo or choose one from your gallery")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0x64748B))
                .padding(.top, 4)

            Spacer().frame(height: 18)

            // ── 1. Take Photo (Opens Camera) ─────────────────
            Button {
                showImageSourceSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showCamera = true
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: 0xEFF6FF))
                            .frame(width: 42, height: 42)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: 0x2563EB))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Take Photo")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: 0x0F172A))

                        Text("Capture a new photo with your camera")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: 0x64748B))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x94A3B8))
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 10)

            // ── 2. Choose from Gallery ───────────────────────
            Button {
                showImageSourceSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showPhotoPicker = true
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: 0xD1FAE5))
                            .frame(width: 42, height: 42)

                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: 0x059669))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose from Gallery")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: 0x0F172A))

                        Text("Pick an existing photo from your device")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: 0x64748B))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x94A3B8))
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 36)
        }
        .padding(.horizontal, 20)
        .background(Color.white)
    }

    // ============================================================
    // 2. PERSONAL & OFFICE / BUSINESS DETAILS CARD
    // ============================================================
    private var personalAndOfficeDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: 0xEFF6FF))
                        .frame(width: 36, height: 36)

                    Image(systemName: "person.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(hex: 0x2563EB))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        isCustomer
                            ? "DEALER PERSONAL & BUSINESS DETAILS"
                            : (isSuperAdmin ? "ADMINISTRATOR PERSONAL & OFFICE DETAILS" : "ADMIN PERSONAL & OFFICE DETAILS")
                    )
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(Color(hex: 0x0F172A))
                    .tracking(0.3)

                    Text(
                        isCustomer
                            ? "Authorized partner profile, registered company name, and shipping address"
                            : "Official staff details, emergency contact number, and office location"
                    )
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(hex: 0x64748B))
                }
            }

            // EditModeBar (Read-only pill on left, Edit Profile button on right)
            HStack {
                // Left Status Pill
                HStack(spacing: 5) {
                    Image(systemName: isEditing ? "pencil" : "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(isEditing ? Color(hex: 0x2563EB) : Color(hex: 0x64748B))

                    Text(isEditing ? "Edit Mode Active" : "Read-only")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isEditing ? Color(hex: 0x2563EB) : Color(hex: 0x64748B))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isEditing ? Color(hex: 0xEFF6FF) : Color(hex: 0xF1F5F9))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isEditing ? Color(hex: 0xBFDBFE) : Color(hex: 0xE2E8F0), lineWidth: 1)
                )

                Spacer()

                // Right Action Button (Edit Profile or Cancel)
                if isEditing {
                    Button {
                        withAnimation {
                            cancelEditing()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                            Text("Cancel")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color(hex: 0x1E293B))
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        withAnimation {
                            startEditing()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Edit Profile")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color(hex: 0x2563EB))
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: 0xBFDBFE), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Form Fields
            VStack(spacing: 12) {
                // 1. Full Name
                fieldBox(
                    label: isCustomer ? "Full Name / Business Name" : "Full Name",
                    text: $name,
                    placeholder: isCustomer ? "e.g. Rajputana Motors" : "Rajputana",
                    isEditable: isEditing
                )

                // 2. Contact / Emergency Phone with "IN  +91" container
                VStack(alignment: .leading, spacing: 4) {
                    Text(isCustomer ? "Mobile Phone" : "Contact / Emergency Phone")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x475569))

                    HStack(spacing: 8) {
                        Text("IN  +91")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x0F172A))
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color(hex: 0xF1F5F9))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                            )

                        TextField("Phone number", text: Binding(
                            get: { phone },
                            set: { phone = String($0.filter { $0.isNumber }.prefix(10)) }
                        ))
                        .disabled(!isEditing)
                        .keyboardType(.numberPad)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: 0x0F172A))
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(isEditing ? Color(hex: 0xF8FAFC) : Color(hex: 0xF8FAFC))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                        )
                    }
                }

                // 3. Official Email Address
                fieldBox(
                    label: isCustomer ? "Email Address" : "Official Email Address",
                    text: $email,
                    placeholder: "superadmin@automob.in",
                    keyboard: .emailAddress,
                    isEditable: isEditing
                )

                // 4. Role Specific Fields
                if isCustomer {
                    fieldBox(
                        label: "GSTIN Number",
                        text: Binding(
                            get: { gstin },
                            set: { gstin = String($0.uppercased().prefix(15)) }
                        ),
                        placeholder: "15-digit GSTIN",
                        isEditable: isEditing
                    )
                } else {
                    fieldBox(
                        label: "Designation & Role",
                        text: $designation,
                        placeholder: "Managing Director & Chief Executive Officer",
                        isEditable: isEditing
                    )

                    fieldBox(
                        label: "Department / Division",
                        text: $department,
                        placeholder: "Executive Management & ERP Operations",
                        isEditable: isEditing
                    )

                    fieldBox(
                        label: "Employee ID / System Code",
                        text: .constant(employeeId.isEmpty ? (isSuperAdmin ? "SADM-001" : "ADM-101") : employeeId),
                        placeholder: "SADM-001",
                        isEditable: false
                    )
                }

                // 5. Headquarters / Office Street Address
                fieldBox(
                    label: isCustomer ? "Street Address" : "Headquarters / Office Street Address",
                    text: $address,
                    placeholder: "Plot 42, Industrial Area Phase III",
                    isEditable: isEditing
                )

                // 6. Two Columns: Country | State
                HStack(spacing: 10) {
                    fieldBox(
                        label: "Country",
                        text: .constant(country.isEmpty ? "India" : country),
                        placeholder: "India",
                        isEditable: false
                    )

                    statePickerBox(label: "State", selectedState: $state, isEditable: isEditing)
                }

                // 7. Two Columns: District / City | PIN / Postal Code
                HStack(spacing: 10) {
                    cityPickerBox(label: "District / City", selectedCity: $city, isEditable: isEditing)

                    fieldBox(
                        label: "PIN / Postal Code",
                        text: Binding(
                            get: { pincode },
                            set: { pincode = String($0.filter { $0.isNumber }.prefix(6)) }
                        ),
                        placeholder: "411026",
                        keyboard: .numberPad,
                        isEditable: isEditing
                    )
                }

                // 8. Save Admin / Dealer Profile Button (Only shown when editing)
                if isEditing {
                    Button {
                        Task { await saveProfile() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15, weight: .bold))
                                Text(isCustomer ? "Save Dealer Profile" : "Save Admin Profile")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: 0x2563EB))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ============================================================
    // 3. ACCOUNT & CREDIT STANDING (Customer Only)
    // ============================================================
    private var customerAccountDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: 0xEFF6FF))
                        .frame(width: 36, height: 36)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(hex: 0x2563EB))
                }

                Text("ACCOUNT & CREDIT STANDING")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(Color(hex: 0x0F172A))
                    .tracking(0.3)
            }

            VStack(spacing: 10) {
                if let code = session?.customerCode, !code.isEmpty {
                    readRow(label: "Customer Code", value: code)
                    Divider()
                }
                if !tallyLedgerName.isEmpty {
                    readRow(label: "Tally Ledger", value: tallyLedgerName)
                    Divider()
                }
                if !priceTier.isEmpty {
                    readRow(label: "Price Tier", value: priceTier)
                    Divider()
                }
                if !paymentTerms.isEmpty {
                    readRow(label: "Payment Terms", value: paymentTerms)
                    Divider()
                }
                if creditLimit > 0 {
                    readRow(label: "Credit Limit", value: CurrencyFormatter.formatINR(creditLimit))
                    Divider()
                }
                readRow(
                    label: "Outstanding Balance",
                    value: CurrencyFormatter.formatINR(outstandingBalance),
                    highlight: outstandingBalance > 0
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ============================================================
    // 4. CHANGE ACCOUNT PASSWORD CARD (Matching Android 1:1)
    // ============================================================
    private var changePasswordCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: 0xEFF6FF))
                        .frame(width: 36, height: 36)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(hex: 0x2563EB))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("CHANGE ACCOUNT PASSWORD")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0F172A))
                        .tracking(0.3)

                    Text("Update your login credentials to keep your partner account secure")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(hex: 0x64748B))
                }
            }

            // Success or Error banner
            if let msg = passwordMessage {
                Text(msg)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x047857))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: 0xD1FAE5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let err = passwordError {
                Text(err)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xDC2626))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: 0xFEE2E2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Password Fields
            VStack(spacing: 12) {
                passwordField(
                    label: "Current Password",
                    text: $currentPassword,
                    placeholder: "Enter current password",
                    isSecure: !showCurrentPass,
                    onToggle: { showCurrentPass.toggle() }
                )

                passwordField(
                    label: "New Password",
                    text: $newPassword,
                    placeholder: "Enter new password (min. 6 chars)",
                    isSecure: !showNewPass,
                    onToggle: { showNewPass.toggle() }
                )

                passwordField(
                    label: "Confirm New Password",
                    text: $confirmPassword,
                    placeholder: "Re-type new password",
                    isSecure: !showConfirmPass,
                    onToggle: { showConfirmPass.toggle() }
                )

                // Key icon + Update Password button
                Button {
                    Task { await updatePassword() }
                } label: {
                    HStack(spacing: 8) {
                        if isChangingPassword {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "key.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Update Password")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                            ? Color(hex: 0x94A3B8)
                            : Color(hex: 0x2563EB)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(isChangingPassword || currentPassword.isEmpty || newPassword.isEmpty)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ============================================================
    // 5. DEALER ASSISTANCE & SUPPORT HOTLINE (Customer Only)
    // ============================================================
    private var supportHotlineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: 0xEFF6FF))
                        .frame(width: 36, height: 36)

                    Image(systemName: "phone.bubble.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(hex: 0x2563EB))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("DEALER ASSISTANCE & SUPPORT HOTLINE")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0F172A))
                        .tracking(0.3)

                    Text("Dedicated customer desk for catalog bookings, credit terms, and dispatch")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0x64748B))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(supportPhoneDisplay)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x0F172A))

                    Spacer()

                    Text("Toll-Free Helpline")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: 0x047857))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: 0xD1FAE5))
                        .clipShape(Capsule())
                }

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: 0x64748B))

                    Text("Operating Hours: Mon – Sat (9:00 AM – 7:00 PM IST)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: 0x334155))
                }

                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        if let url = URL(string: supportPhoneDial) {
                            Link(destination: url) {
                                HStack(spacing: 6) {
                                    Image(systemName: "phone.fill")
                                    Text("Call Support")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(Color(hex: 0x0B1220))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        if let url = URL(string: supportEmail) {
                            Link(destination: url) {
                                HStack(spacing: 6) {
                                    Image(systemName: "envelope.fill")
                                    Text("Email Desk")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(hex: 0x0F172A))
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
                            }
                        }
                    }

                    if let url = URL(string: supportWhatsApp) {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "message.fill")
                                Text("WhatsApp Customer Desk")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: 0x047857))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color(hex: 0xD1FAE5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(hex: 0xF8FAFC))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // ============================================================
    // 6. SIGN OUT OF ACCOUNT CARD (Matching Android 1:1)
    // ============================================================
    private var signOutCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: 0xDC2626))

            VStack(alignment: .leading, spacing: 2) {
                Text("SIGN OUT OF ACCOUNT")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(Color(hex: 0xDC2626))

                Text("Disconnect your active session on this device")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(hex: 0x64748B))
            }

            Spacer()

            Button {
                showSignOutAlert = true
            } label: {
                Text("Log Out")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xDC2626))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0xFEE2E2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: 0xFECACA), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: 0xFECACA), lineWidth: 1)
        )
    }

    // ============================================================
    // STANDALONE TOP BAR & BOTTOM BAR (For Standalone / Full Previews)
    // ============================================================
    private var standaloneTopBar: some View {
        HStack(spacing: 12) {
            Button {
                if let onOpenDrawer = onOpenDrawer {
                    onOpenDrawer()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Text("Rajputana Automobiles")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.black)

            Spacer()

            Button {
                onOpenNotifications?()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(Color.black)
                        .frame(width: 44, height: 44)

                    let unread = SessionManager.shared.unreadNotificationCount
                    if unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(minWidth: 17, minHeight: 17)
                            .background(Color(hex: 0x2563EB))
                            .clipShape(Circle())
                            .offset(x: -6, y: 6)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(hex: 0xE2E8F0)),
            alignment: .bottom
        )
    }

    private var standaloneBottomBar: some View {
        HStack(spacing: 0) {
            bottomTabItem(title: "Dashboard", icon: "square.grid.2x2", isSelected: false)
            bottomTabItem(title: "Customers", icon: "person.2", isSelected: false)
            bottomTabItem(title: "Orders", icon: "clipboard", isSelected: false)
            bottomTabItem(title: "Inventory", icon: "shippingbox", isSelected: false)
            bottomTabItem(title: "Ledger", icon: "book.closed", isSelected: false)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(hex: 0xE2E8F0)),
                    alignment: .top
                )
        )
    }

    @ViewBuilder
    private func bottomTabItem(title: String, icon: String, isSelected: Bool) -> some View {
        Button {
            dismiss()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x8E8E93))
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0x8E8E93))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // ============================================================
    // HELPER SUBVIEWS
    // ============================================================
    @ViewBuilder
    private func fieldBox(
        label: String,
        text: Binding<String>,
        placeholder: String,
        keyboard: UIKeyboardType = .default,
        isEditable: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0x475569))

            TextField(placeholder, text: text)
                .disabled(!isEditable)
                .keyboardType(keyboard)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: 0x0F172A))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color(hex: 0xF8FAFC))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private func statePickerBox(label: String, selectedState: Binding<String>, isEditable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0x475569))

            if isEditable {
                Menu {
                    ForEach(availableStates, id: \.self) { s in
                        Button(s) {
                            selectedState.wrappedValue = s
                            city = DistrictDataLoader.shared.districts(for: s).first ?? city
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedState.wrappedValue.isEmpty ? "Select" : selectedState.wrappedValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: 0x0F172A))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: 0x64748B))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color(hex: 0xF8FAFC))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                    )
                }
            } else {
                HStack {
                    Text(selectedState.wrappedValue.isEmpty ? "Maharashtra" : selectedState.wrappedValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: 0x0F172A))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color(hex: 0xF8FAFC))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func cityPickerBox(label: String, selectedCity: Binding<String>, isEditable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0x475569))

            if isEditable {
                Menu {
                    ForEach(availableDistricts, id: \.self) { d in
                        Button(d) {
                            selectedCity.wrappedValue = d
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCity.wrappedValue.isEmpty ? "Select" : selectedCity.wrappedValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: 0x0F172A))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: 0x64748B))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color(hex: 0xF8FAFC))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                    )
                }
            } else {
                HStack {
                    Text(selectedCity.wrappedValue.isEmpty ? "Punee" : selectedCity.wrappedValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: 0x0F172A))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color(hex: 0xF8FAFC))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func passwordField(
        label: String,
        text: Binding<String>,
        placeholder: String,
        isSecure: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0x475569))

            HStack {
                if isSecure {
                    SecureField(placeholder, text: text)
                        .font(.system(size: 14))
                } else {
                    TextField(placeholder, text: text)
                        .font(.system(size: 14))
                }

                Button(action: onToggle) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: 0x94A3B8))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color(hex: 0xF8FAFC))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func readRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0x64748B))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(highlight ? Color(hex: 0xDC2626) : Color(hex: 0x0F172A))
                .multilineTextAlignment(.trailing)
        }
    }

    // ============================================================
    // EDITING & DIRTY TRACKING
    // ============================================================
    private func startEditing() {
        initialName = name
        initialPhone = phone
        initialEmail = email
        initialGstin = gstin
        initialAddress = address
        initialCountry = country
        initialState = state
        initialCity = city
        initialPincode = pincode
        initialDesignation = designation
        initialDepartment = department
        isEditing = true
    }

    private func cancelEditing() {
        name = initialName
        phone = initialPhone
        email = initialEmail
        gstin = initialGstin
        address = initialAddress
        country = initialCountry
        state = initialState
        city = initialCity
        pincode = initialPincode
        designation = initialDesignation
        department = initialDepartment
        isEditing = false
    }

    // ============================================================
    // DATA LOADING & PERSISTENCE
    // ============================================================
    private func loadProfile() async {
        guard let s = session else { return }

        // 1. Try loading cached edits from UserDefaults first
        let cacheKey = "user_profile_cache_\(s.userId)"
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(StoredProfileModel.self, from: data) {
            applyStoredProfile(cached)
            return
        }

        // 2. Setup baseline defaults matching Android screenshots
        if isSuperAdmin {
            self.name = s.name.isEmpty ? "Rajputana" : s.name
            self.phone = "9820011224"
            self.email = s.email.isEmpty ? "superadmin@automob.in" : s.email
            self.designation = "Managing Director & Chief Executive Officer"
            self.department = "Executive Management & ERP Operations"
            self.employeeId = "SADM-001"
            self.address = "Plot 42, Industrial Area Phase III"
            self.country = "India"
            self.state = "Maharashtra"
            self.city = "Punee"
            self.pincode = "411026"
        } else if !isCustomer {
            self.name = s.name.isEmpty ? "Administrator" : s.name
            self.phone = "9820011225"
            self.email = s.email.isEmpty ? "admin@automob.in" : s.email
            self.designation = "Operations & Fleet Manager"
            self.department = "Automobile Parts & Logistics"
            self.employeeId = "ADM-101"
            self.address = "Plot 18, Transport Nagar, Ajmer Road"
            self.country = "India"
            self.state = "Rajasthan"
            self.city = "Jaipur"
            self.pincode = "302006"
        } else {
            self.name = s.name
            self.phone = s.customerPhone ?? ""
            self.email = s.customerEmail ?? s.email
            self.gstin = s.gstin ?? ""
            self.address = s.customerAddress ?? ""
            self.country = "India"
            self.state = "Rajasthan"
            self.city = "Jaipur"
            self.pincode = ""
        }

        // 3. If customer, fetch live details
        if isCustomer {
            let candidate = s.customerCode ?? s.userId
            if let detail = try? await CustomerService.shared.fetchCustomerDetail(token: s.token, id: candidate) {
                await MainActor.run {
                    self.name = detail.name
                    if let p = detail.phone, !p.isEmpty { self.phone = p }
                    if let e = detail.email, !e.isEmpty { self.email = e }
                    if let g = detail.gstin, !g.isEmpty { self.gstin = g }
                    if let a = detail.address, !a.isEmpty { self.address = a }
                    if let st = detail.state, !st.isEmpty { self.state = st }
                    if let ct = detail.city, !ct.isEmpty { self.city = ct }
                    if let pin = detail.pincode, !pin.isEmpty { self.pincode = pin }
                    if let av = detail.avatarUrl ?? detail.avatar, !av.isEmpty { self.avatarUrl = av }
                    self.tallyLedgerName = detail.tallyLedgerName ?? ""
                    self.priceTier = detail.priceTier ?? ""
                    self.paymentTerms = detail.paymentTerms ?? ""
                    self.creditLimit = detail.creditLimit ?? 0.0
                    self.outstandingBalance = detail.outstandingBalance ?? 0.0
                }
            }
        }
    }

    private func saveProfile() async {
        guard let s = session else { return }
        isSaving = true

        let stored = StoredProfileModel(
            name: name.trimmingCharacters(in: .whitespaces),
            phone: phone.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            gstin: gstin.trimmingCharacters(in: .whitespaces).uppercased(),
            address: address.trimmingCharacters(in: .whitespaces),
            country: country.trimmingCharacters(in: .whitespaces),
            state: state.trimmingCharacters(in: .whitespaces),
            city: city.trimmingCharacters(in: .whitespaces),
            pincode: pincode.trimmingCharacters(in: .whitespaces),
            designation: designation.trimmingCharacters(in: .whitespaces),
            department: department.trimmingCharacters(in: .whitespaces),
            employeeId: employeeId,
            avatarUrl: avatarUrl
        )

        // Save locally to cache so edits persist
        let cacheKey = "user_profile_cache_\(s.userId)"
        if let enc = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(enc, forKey: cacheKey)
        }

        // Also push to server if customer
        if isCustomer {
            let candidate = s.customerCode ?? s.userId
            let req = EditCustomerRequest(
                name: name.trimmingCharacters(in: .whitespaces),
                phone: phone.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                address: address.trimmingCharacters(in: .whitespaces),
                city: city.trimmingCharacters(in: .whitespaces),
                state: state.trimmingCharacters(in: .whitespaces),
                pincode: pincode.trimmingCharacters(in: .whitespaces),
                gstin: gstin.trimmingCharacters(in: .whitespaces).uppercased(),
                creditLimit: nil,
                paymentTerms: nil,
                priceTier: nil,
                password: nil
            )
            _ = try? await CustomerService.shared.updateCustomer(token: s.token, id: candidate, request: req)
        }

        await MainActor.run {
            self.isSaving = false
            self.isEditing = false
            self.showToast("Profile updated successfully")
        }
    }

    private func applyStoredProfile(_ model: StoredProfileModel) {
        if !model.name.isEmpty { self.name = model.name }
        if !model.phone.isEmpty { self.phone = model.phone }
        if !model.email.isEmpty { self.email = model.email }
        if !model.gstin.isEmpty { self.gstin = model.gstin }
        if !model.address.isEmpty { self.address = model.address }
        if !model.country.isEmpty { self.country = model.country }
        if !model.state.isEmpty { self.state = model.state }
        if !model.city.isEmpty { self.city = model.city }
        if !model.pincode.isEmpty { self.pincode = model.pincode }
        if !model.designation.isEmpty { self.designation = model.designation }
        if !model.department.isEmpty { self.department = model.department }
        if !model.employeeId.isEmpty { self.employeeId = model.employeeId }
        if !model.avatarUrl.isEmpty { self.avatarUrl = model.avatarUrl }
    }

    private func handlePhotoPicked(_ item: PhotosPickerItem) async {
        isUploadingAvatar = true
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await processAndUploadImage(image)
                return
            }
            await MainActor.run { self.isUploadingAvatar = false }
        } catch {
            await MainActor.run {
                self.isUploadingAvatar = false
                self.showToast("Avatar update failed: \(error.localizedDescription)")
            }
        }
    }

    private func processAndUploadImage(_ image: UIImage) async {
        isUploadingAvatar = true
        // Resize for avatar
        let maxDimension: CGFloat = 360
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.8)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let jpegData = (scaledImage ?? image).jpegData(compressionQuality: 0.75) {
            let base64 = "data:image/jpeg;base64," + jpegData.base64EncodedString()
            await MainActor.run {
                self.avatarUrl = base64
                self.isUploadingAvatar = false
                self.showToast("Profile photo updated!")

                // Persist avatar in cache
                if let s = self.session {
                    let cacheKey = "user_profile_cache_\(s.userId)"
                    let stored = StoredProfileModel(
                        name: self.name,
                        phone: self.phone,
                        email: self.email,
                        gstin: self.gstin,
                        address: self.address,
                        country: self.country,
                        state: self.state,
                        city: self.city,
                        pincode: self.pincode,
                        designation: self.designation,
                        department: self.department,
                        employeeId: self.employeeId,
                        avatarUrl: base64
                    )
                    if let enc = try? JSONEncoder().encode(stored) {
                        UserDefaults.standard.set(enc, forKey: cacheKey)
                    }
                }
            }
        } else {
            await MainActor.run { self.isUploadingAvatar = false }
        }
    }

    private func updatePassword() async {
        guard newPassword == confirmPassword else {
            passwordError = "New passwords don't match."
            return
        }
        guard newPassword.count >= 6 else {
            passwordError = "New password must be at least 6 characters."
            return
        }
        guard newPassword != currentPassword else {
            passwordError = "New password must be different from current."
            return
        }
        guard let s = session else { return }

        isChangingPassword = true
        passwordMessage = nil
        passwordError = nil

        do {
            let identifier = s.customerEmail ?? s.email
            let success = try await AuthService.shared.changePassword(
                token: s.token,
                identifier: identifier,
                oldPass: currentPassword,
                newPass: newPassword
            )
            await MainActor.run {
                self.isChangingPassword = false
                if success {
                    self.passwordMessage = "Password updated successfully!"
                    self.currentPassword = ""
                    self.newPassword = ""
                    self.confirmPassword = ""
                } else {
                    self.passwordError = "Unable to update password. Check your current password."
                }
            }
        } catch {
            await MainActor.run {
                self.isChangingPassword = false
                self.passwordError = error.localizedDescription
            }
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                withAnimation { toastMessage = nil }
            }
        }
    }
}

// ============================================================
// PROFILE CAMERA VIEW (Native Hardware + Simulator Scanner)
// ============================================================
public struct ProfileCameraView: View {
    public var onImageCaptured: (UIImage) -> Void
    public var onDismiss: () -> Void

    @State private var isFlashOn: Bool = false
    @State private var isFrontCamera: Bool = true

    public init(onImageCaptured: @escaping (UIImage) -> Void, onDismiss: @escaping () -> Void) {
        self.onImageCaptured = onImageCaptured
        self.onDismiss = onDismiss
    }

    public var body: some View {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            UIKitCameraPicker { image in
                onImageCaptured(image)
            } onCancel: {
                onDismiss()
            }
            .ignoresSafeArea()
        } else {
            // Realistic iOS Camera Scanner & Viewfinder for Simulator
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Camera Controls Bar
                    HStack {
                        Button {
                            isFlashOn.toggle()
                        } label: {
                            Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(isFlashOn ? Color.yellow : Color.white)
                                .frame(width: 44, height: 44)
                        }

                        Spacer()

                        Text("PHOTO")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.yellow)

                        Spacer()

                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.white)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    Spacer()

                    // Circular Portrait Face/Avatar Guide
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: 0x1E293B).opacity(0.8))
                            .frame(width: 300, height: 360)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                            )

                        VStack(spacing: 16) {
                            Circle()
                                .stroke(Color.yellow.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                .frame(width: 170, height: 170)
                                .overlay(
                                    Image(systemName: "person.crop.circle")
                                        .font(.system(size: 90))
                                        .foregroundStyle(Color.white.opacity(0.4))
                                )

                            Text("Align face within the frame")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                    }

                    Spacer()

                    // Bottom Camera Controls (Shutter, Rotate, Gallery)
                    HStack(alignment: .center) {
                        Spacer()

                        // Shutter Button (iOS Camera Style)
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .heavy)
                            impact.impactOccurred()
                            captureSimulatedPhoto()
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 72, height: 72)

                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Flip Camera Button
                        Button {
                            isFrontCamera.toggle()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 48, height: 48)

                                Image(systemName: "camera.rotate.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.white)
                            }
                        }
                        .padding(.trailing, 24)
                    }
                    .frame(height: 110)
                    .background(Color.black)
                }
            }
        }
    }

    private func captureSimulatedPhoto() {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        let captured = renderer.image { ctx in
            // Render a stylish gradient avatar
            let c1 = UIColor(red: 76.0/255.0, green: 104.0/255.0, blue: 245.0/255.0, alpha: 1.0).cgColor
            let c2 = UIColor(red: 36.0/255.0, green: 83.0/255.0, blue: 232.0/255.0, alpha: 1.0).cgColor
            let colors = [c1, c2]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0]) {
                ctx.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 400, y: 400), options: [])
            }

            // Draw a portrait silhouette
            let text = "R"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 140, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attrs)
            let rect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: rect, withAttributes: attrs)
        }
        onImageCaptured(captured)
    }
}

// ── Persistent Cached Model ────────────────────────────────────
private struct StoredProfileModel: Codable {
    var name: String
    var phone: String
    var email: String
    var gstin: String
    var address: String
    var country: String
    var state: String
    var city: String
    var pincode: String
    var designation: String
    var department: String
    var employeeId: String
    var avatarUrl: String
}
