import SwiftUI
import PhotosUI

public struct InventoryDetailView: View {
    public let itemId: String
    public var canEdit: Bool = true
    public var onBack: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var item: InventoryItem? = nil
    @State private var isLoading: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var currentPage: Int = 0

    @State private var showPhotosSheet: Bool = ProcessInfo.processInfo.arguments.contains("-showManagePhotos")
    @State private var showAddPhotoSheet: Bool = ProcessInfo.processInfo.arguments.contains("-showAddPhoto")
    @State private var showCameraPicker: Bool = false
    @State private var showDeleteDialog: Bool = false
    @State private var isDeleting: Bool = false
    @State private var showZoomViewer: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isUploadingPhoto: Bool = false
    @State private var errorMessage: String? = nil

    public init(itemId: String, canEdit: Bool = true, onBack: (() -> Void)? = nil) {
        self.itemId = itemId
        self.canEdit = canEdit
        self.onBack = onBack
    }

    private var allImages: [String] {
        guard let it = item else { return [] }
        var list = it.images?.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? []
        if list.isEmpty, let u = it.imageUrl, !u.isEmpty {
            list = [u]
        }
        return list
    }

    public var body: some View {
        ZStack {
            Color(hex: 0xF4F6F9).ignoresSafeArea()

            if isLoading && item == nil {
                VStack(spacing: 16) {
                    ShimmerBox(height: 240, cornerRadius: 16)
                    ShimmerBox(height: 60, cornerRadius: 12)
                    ShimmerBox(height: 120, cornerRadius: 16)
                    ShimmerBox(height: 100, cornerRadius: 16)
                }
                .padding(16)
            } else if let it = item {
                ScrollView {
                    VStack(spacing: 12) {
                        // ── HERO IMAGE CAROUSEL ───────────────────
                        heroCarousel(it)

                        // ── THUMBNAIL STRIP + ADD PHOTO ───────────
                        photosStrip

                        // ── HEADER CARD (OEM + BADGE + TITLE) ─────
                        headerCard(it)

                        // ── QUICK STATS (PRICE + LIVE STOCK) ──────
                        quickStatsCard(it)

                        // ── ACTION BUTTONS: MANAGE PHOTOS & DELETE ─
                        if canEdit {
                            actionButtonsRow
                        }

                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                }
                .refreshable {
                    await reloadItem()
                }
            }

            // ── DELETE CONFIRMATION DIALOG ────────────────────────
            if showDeleteDialog, let it = item {
                DeleteInventoryDialog(
                    item: it,
                    isDeleting: isDeleting,
                    onCancel: { showDeleteDialog = false },
                    onConfirm: {
                        Task {
                            isDeleting = true
                            if let session = SessionManager.shared.session {
                                try? await InventoryService.shared.deleteItem(token: session.token, id: it.id)
                            }
                            isDeleting = false
                            showDeleteDialog = false
                            dismiss()
                        }
                    }
                )
            }

            // ── FULLSCREEN IMAGE ZOOM ─────────────────────────────
            if showZoomViewer, !allImages.isEmpty {
                fullscreenZoomOverlay
            }

            // ── CAMERA CAPTURE MODAL ──────────────────────────────
            if showCameraPicker {
                CameraCaptureModal(
                    orderNumber: item?.itemCode ?? "Product",
                    customerName: item?.displayName ?? "Item",
                    onImageCaptured: { capturedImage in
                        showCameraPicker = false
                        if let data = capturedImage.jpegData(compressionQuality: 0.8) {
                            Task { await uploadNewPhoto(data: data) }
                        }
                    },
                    onDismiss: {
                        showCameraPicker = false
                    }
                )
                .transition(.opacity)
                .zIndex(200)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    if let onBack = onBack {
                        onBack()
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Product Details")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    Task { await reloadItem() }
                }) {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: 0x0F172A))
                    }
                }
            }
        }
        .task {
            await loadItem()
        }
        .sheet(isPresented: $showPhotosSheet) {
            if let it = item {
                PhotoManagerSheet(item: it) { updated in
                    self.item = updated
                }
            }
        }
        .sheet(isPresented: $showAddPhotoSheet) {
            addPhotoSourceSheet
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
        }
        .photosPicker(isPresented: .init(
            get: { selectedPhotoItem != nil },
            set: { if !$0 { selectedPhotoItem = nil } }
        ), selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await uploadNewPhoto(data: data)
                }
                selectedPhotoItem = nil
            }
        }
    }

    // ── HERO CAROUSEL ─────────────────────────────────────────
    private func heroCarousel(_ it: InventoryItem) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack(alignment: .topTrailing) {
                if allImages.isEmpty {
                    ZStack {
                        Color.white
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 44))
                                .foregroundColor(Color(hex: 0xCBD5E1))
                            Text("No product images available")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: 0x94A3B8))
                        }
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    TabView(selection: $currentPage) {
                        ForEach(Array(allImages.enumerated()), id: \.offset) { index, url in
                            RemoteImageView(urlString: url, contentMode: .fit)
                                .tag(index)
                                .onTapGesture {
                                    showZoomViewer = true
                                }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 240)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // Zoom Icon on Top-Right
                if !allImages.isEmpty {
                    Button(action: { showZoomViewer = true }) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.85))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    .padding(12)
                }
            }

            // Page Badge on Bottom-Right: "1/1"
            if !allImages.isEmpty {
                Text("\(currentPage + 1)/\(allImages.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(12)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
    }

    // ── THUMBNAIL STRIP + ADD PHOTO ───────────────────────────
    private var photosStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(allImages.enumerated()), id: \.offset) { index, url in
                    let isSelected = currentPage == index
                    Button {
                        currentPage = index
                    } label: {
                        RemoteImageView(urlString: url, contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color(hex: 0x2563EB) : Color(hex: 0xE2E8F0), lineWidth: isSelected ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // Add Photo Button (+)
                Button(action: { showAddPhotoSheet = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(hex: 0xBFDBFE), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0xEFF6FF)))
                            .frame(width: 56, height: 56)

                        if isUploadingPhoto {
                            ProgressView()
                                .tint(Color(hex: 0x2563EB))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: 0x2563EB))
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isUploadingPhoto)
            }
            .padding(.vertical, 2)
        }
    }

    // ── HEADER CARD ───────────────────────────────────────────
    private func headerCard(_ it: InventoryItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                // OEM Badge
                Text("OEM: \(it.itemCode.isEmpty ? it.id : it.itemCode)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                // Stock Badge
                stockStatusBadge(it)
            }

            Text(it.displayName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: 0x0F172A))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
    }

    // ── STOCK STATUS BADGE ────────────────────────────────────
    private func stockStatusBadge(_ it: InventoryItem) -> some View {
        Group {
            if it.isOutOfStock {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                    Text("Out of Stock")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(Color(hex: 0xDC2626))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: 0xFEE2E2))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: 0xFECACA), lineWidth: 1))
            } else if it.isLowStock {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                    Text("Low Stock (\(it.stockLevelDisplay) \(it.unit ?? "pc"))")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(Color(hex: 0xD97706))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: 0xFEF3C7))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: 0xFDE68A), lineWidth: 1))
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                    Text("In Stock (\(it.stockLevelDisplay) \(it.unit ?? "pc"))")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(Color(hex: 0x059669))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: 0xD1FAE5))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: 0xA7F3D0), lineWidth: 1))
            }
        }
    }

    // ── QUICK STATS CARD ──────────────────────────────────────
    private func quickStatsCard(_ it: InventoryItem) -> some View {
        HStack(spacing: 0) {
            // Unit Price
            VStack(alignment: .leading, spacing: 4) {
                Text("UNIT PRICE")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: 0x94A3B8))
                    .tracking(0.5)

                Text(formatCurrency(it.unitPrice ?? 0.0))
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Text("Excl. \(it.gst ?? 18)% GST")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: 0x64748B))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(Color(hex: 0xE2E8F0))
                .frame(width: 1, height: 50)
                .padding(.horizontal, 14)

            // Live Stock
            VStack(alignment: .leading, spacing: 4) {
                Text("LIVE STOCK")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: 0x94A3B8))
                    .tracking(0.5)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(it.stockLevelDisplay)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(it.isLowStock ? Color(hex: 0x2563EB) : Color(hex: 0x0F172A))

                    Text(it.unit?.isEmpty == false ? it.unit! : "pc")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x64748B))
                }

                Text("Min Safety: \(Int(it.minThreshold ?? 20))")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: 0x64748B))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
    }

    // ── ACTION BUTTONS: MANAGE PHOTOS & DELETE ────────────────
    private var actionButtonsRow: some View {
        HStack(spacing: 8) {
            Button(action: { showPhotosSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Manage Photos")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(Color(hex: 0x2563EB))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color(hex: 0xEFF6FF))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0x2563EB), lineWidth: 1))
            }

            Button(action: { showDeleteDialog = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                    Text("Delete Item")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(Color(hex: 0xDC2626))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color(hex: 0xFEE2E2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xFECACA), lineWidth: 1))
            }
        }
    }

    // ── ADD PHOTO SOURCE SHEET (IMAGE 7) ──────────────────────
    private var addPhotoSourceSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add Product Photo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Text("Choose how you want to add this photo")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0x64748B))
            }
            .padding(.top, 8)

            // Option 1: Take Photo (Camera)
            Button {
                showAddPhotoSheet = false
                showCameraPicker = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0xEFF6FF))
                            .frame(width: 44, height: 44)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: 0x2563EB))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Take Photo")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))

                        Text("Use device camera to capture new photo")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0x64748B))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: 0x94A3B8))
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Option 2: Choose from Gallery (PhotosPicker)
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0xEFF6FF))
                            .frame(width: 44, height: 44)

                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: 0x2563EB))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose from Gallery")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))

                        Text("Select existing image from photo library")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0x64748B))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: 0x94A3B8))
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                showAddPhotoSheet = false
            })

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // ── FULLSCREEN ZOOM VIEWER ────────────────────────────────
    private var fullscreenZoomOverlay: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(Array(allImages.enumerated()), id: \.offset) { index, url in
                    RemoteImageView(urlString: url, contentMode: .fit)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())

            VStack {
                HStack {
                    Spacer()
                    Button(action: { showZoomViewer = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(16)
                }
                Spacer()

                Text("\(currentPage + 1) of \(allImages.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.bottom, 30)
            }
        }
        .zIndex(150)
    }

    // ── DATA OPS ──────────────────────────────────────────────
    private func loadItem() async {
        guard let token = SessionManager.shared.session?.token else { return }
        isLoading = true
        do {
            let fetched = try await InventoryService.shared.fetchInventoryItem(token: token, id: itemId)
            await MainActor.run {
                self.item = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func reloadItem() async {
        guard let token = SessionManager.shared.session?.token else { return }
        isRefreshing = true
        do {
            let fetched = try await InventoryService.shared.fetchInventoryItem(token: token, id: itemId)
            await MainActor.run {
                self.item = fetched
                self.isRefreshing = false
            }
        } catch {
            await MainActor.run {
                self.isRefreshing = false
            }
        }
    }

    private func uploadNewPhoto(data: Data) async {
        guard let token = SessionManager.shared.session?.token, let it = item else { return }
        await MainActor.run { isUploadingPhoto = true }

        let base64 = "data:image/jpeg;base64," + data.base64EncodedString()
        do {
            let updated = try await InventoryService.shared.uploadItemImage(token: token, id: it.id, imageBase64DataUri: base64)
            await MainActor.run {
                self.item = updated
                self.isUploadingPhoto = false
                self.currentPage = max(0, (self.allImages.count - 1))
            }
        } catch {
            await MainActor.run {
                self.isUploadingPhoto = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "₹%.2f", amount)
    }
}
