import SwiftUI
import PhotosUI

public struct PhotoManagerSheet: View {
    public let item: InventoryItem
    public var onUpdated: (InventoryItem) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var images: [String] = []
    @State private var coverUrl: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    @State private var isUploading: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successToast: String? = nil

    // Amber palette for "Active Cover" badge
    private let coverBadgeBg = Color(hex: 0xFEF3C7)
    private let coverBadgeFg = Color(hex: 0x92400E)
    private let coverBadgeIcon = Color(hex: 0xD97706)

    public init(item: InventoryItem, onUpdated: @escaping (InventoryItem) -> Void) {
        self.item = item
        self.onUpdated = onUpdated

        let list = (item.images?.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? [])
        let initialList = list.isEmpty ? (item.imageUrl?.isEmpty == false ? [item.imageUrl!] : []) : list
        let initialCover = item.imageUrl?.isEmpty == false && initialList.contains(item.imageUrl!)
            ? item.imageUrl!
            : initialList.first ?? ""

        _images = State(initialValue: initialList)
        _coverUrl = State(initialValue: initialCover)
    }

    private var hasChanges: Bool {
        let originalList = item.images ?? (item.imageUrl != nil ? [item.imageUrl!] : [])
        let originalCover = item.imageUrl ?? ""
        return images != originalList || coverUrl != originalCover
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // ── HEADER: ERP MODULE CHIP + COUNT + CLOSE ─────────
                HStack(alignment: .center) {
                    Text("ERP MODULE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(LiquidTheme.electricBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0xEFF6FF))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(images.count == 1 ? "1 Photo" : "\(images.count) Photos")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: 0x64748B))

                    Spacer()

                    Button(action: {
                        if !isSaving && !isUploading { dismiss() }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: 0x94A3B8))
                            .frame(width: 32, height: 32)
                            .background(Color(hex: 0xF1F5F9))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer().frame(height: 10)

                // ── TITLE & SUBTITLE ─────────────────────────────────
                VStack(alignment: .leading, spacing: 4) {
                    Text("Manage Uploaded Photos")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))

                    let subtitle = [item.displayName, item.itemCode]
                        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                        .joined(separator: " — ")
                    Text(subtitle.isEmpty ? "Product photos" : subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: 0x64748B))
                        .lineLimit(1)
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 14)

                // ── INFO BANNER ──────────────────────────────────────
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(LiquidTheme.electricBlue)
                        .font(.system(size: 14))

                    Text("Set the primary cover photo or delete invalid photos before saving.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(LiquidTheme.electricBlue)
                        .lineLimit(2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: 0xEFF6FF))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xDBEAFE), lineWidth: 1))
                .padding(.horizontal, 20)

                if let err = errorMessage {
                    Text(err)
                        .font(AppTypography.caption)
                        .foregroundColor(Color(hex: 0xDC2626))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                if let toast = successToast {
                    Text(toast)
                        .font(AppTypography.caption)
                        .foregroundColor(Color(hex: 0x059669))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                Spacer().frame(height: 14)

                // ── PHOTO LIST (SCROLLABLE) ──────────────────────────
                ScrollView {
                    VStack(spacing: 10) {
                        if images.isEmpty {
                            VStack(spacing: 8) {
                                Spacer().frame(height: 24)
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 36))
                                    .foregroundColor(Color(hex: 0xCBD5E1))
                                Text("No photos uploaded yet for this product.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: 0x94A3B8))
                                Spacer().frame(height: 24)
                            }
                        } else {
                            ForEach(Array(images.enumerated()), id: \.offset) { index, url in
                                photoRow(index: index, url: url)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }

                Divider().padding(.top, 8)

                // ── BOTTOM ACTIONS ───────────────────────────────────
                VStack(spacing: 10) {
                    // Upload button
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 8) {
                            if isUploading {
                                ProgressView()
                                    .tint(LiquidTheme.electricBlue)
                                Text("Uploading New Photo…")
                            } else {
                                Image(systemName: "camera.fill")
                                Text("Upload New Photo")
                            }
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(LiquidTheme.electricBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: 0xEFF6FF))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xBFDBFE), lineWidth: 1))
                    }
                    .disabled(isUploading || isSaving)

                    HStack(spacing: 12) {
                        Button(action: {
                            if !isSaving && !isUploading { dismiss() }
                        }) {
                            Text("Cancel")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: 0x0F172A))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(hex: 0xF1F5F9))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button(action: {
                            Task { await saveChanges() }
                        }) {
                            HStack(spacing: 6) {
                                if isSaving {
                                    ProgressView().tint(.white)
                                    Text("Saving…")
                                } else {
                                    Text("Save Changes (\(images.count))")
                                }
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(hasChanges && !images.isEmpty && !isSaving ? LiquidTheme.electricBlue : Color(hex: 0x93C5FD))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!hasChanges || images.isEmpty || isSaving || isUploading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .navigationBarHidden(true)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        await uploadPhoto(data: data)
                    }
                }
            }
        }
    }

    private func photoRow(index: Int, url: String) -> some View {
        let isCover = (url == coverUrl)

        return HStack(spacing: 12) {
            // Thumbnail
            RemoteImageView(urlString: url, contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))

            // Label & Cover Status
            VStack(alignment: .leading, spacing: 6) {
                Text("Photo \(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                if isCover {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(coverBadgeIcon)
                        Text("Active Cover")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(coverBadgeFg)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(coverBadgeBg)
                    .clipShape(Capsule())
                } else {
                    Button(action: {
                        coverUrl = url
                    }) {
                        Text("Set Cover")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: 0xF1F5F9))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Delete button
            Button(action: {
                deletePhoto(at: index)
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(images.count > 1 ? Color(hex: 0xDC2626) : Color(hex: 0xFCA5A5))
                    .frame(width: 36, height: 36)
            }
            .disabled(images.count <= 1 || isSaving)
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCover ? LiquidTheme.electricBlue : Color(hex: 0xE2E8F0), lineWidth: isCover ? 2 : 1)
        )
    }

    private func deletePhoto(at index: Int) {
        guard index < images.count else { return }
        let removed = images.remove(at: index)
        if removed == coverUrl {
            coverUrl = images.first ?? ""
        }
    }

    private func uploadPhoto(data: Data) async {
        guard let token = SessionManager.shared.session?.token else { return }
        isUploading = true
        errorMessage = nil
        successToast = nil

        let base64 = data.base64EncodedString()
        let dataUri = "data:image/jpeg;base64,\(base64)"

        do {
            let updated = try await InventoryService.shared.uploadItemImage(token: token, id: item.id, imageBase64DataUri: dataUri)
            await MainActor.run {
                self.isUploading = false
                let freshList = (updated.images?.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? [])
                let list = freshList.isEmpty ? (updated.imageUrl != nil ? [updated.imageUrl!] : []) : freshList
                self.images = list
                if self.coverUrl.isEmpty || !list.contains(self.coverUrl) {
                    self.coverUrl = updated.imageUrl ?? list.first ?? ""
                }
                self.successToast = "Photo uploaded successfully!"
                self.onUpdated(updated)
            }
        } catch {
            await MainActor.run {
                self.isUploading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func saveChanges() async {
        guard let token = SessionManager.shared.session?.token else { return }
        isSaving = true
        errorMessage = nil

        let payload: [String: Any] = [
            "images": images,
            "imageUrl": coverUrl
        ]

        do {
            let updated = try await InventoryService.shared.updateInventoryItem(token: token, id: item.id, changes: payload)
            await MainActor.run {
                self.isSaving = false
                self.onUpdated(updated)
                dismiss()
            }
        } catch {
            await MainActor.run {
                self.isSaving = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
