import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import QuickLook
import UIKit

public struct LorryReceiptSheet: View {
    public let order: OrderModel
    public var onSaved: (OrderModel) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var lrNumber: String = ""
    @State private var transporter: String = ""
    @State private var vehicleNumber: String = ""
    @State private var lrNotes: String = ""

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageDataUri: String? = nil
    @State private var selectedFileName: String? = nil
    @State private var selectedFileSize: String? = nil

    @State private var isEditMode: Bool = false
    @State private var isUploading: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var showDocPicker: Bool = false
    @State private var showCameraPicker: Bool = ProcessInfo.processInfo.arguments.contains("-openCamera")
    @State private var previewUrl: URL? = nil
    @State private var errorMessage: String? = nil

    // Android 1:1 Palette
    private let lrGreenBg = Color(hex: 0xF6FFFB)
    private let lrGreenBorder = Color(hex: 0xA7F3D0)
    private let lrGreenText = Color(hex: 0x059669)
    private let lrGreenBgSoft = Color(hex: 0xD5FAE8)
    private let lrGreenDot = Color(hex: 0x10B981)

    public init(order: OrderModel, onSaved: @escaping (OrderModel) -> Void) {
        self.order = order
        self.onSaved = onSaved

        _lrNumber = State(initialValue: order.lrNumber ?? "")
        _transporter = State(initialValue: order.transporter ?? "")
        _vehicleNumber = State(initialValue: order.vehicleNumber ?? "")
        _lrNotes = State(initialValue: order.lrNotes ?? "")
        _selectedFileName = State(initialValue: order.lrFileName)
        _selectedFileSize = State(initialValue: order.lrFileSize)

        // If existing LR, start in Saved View, else in Edit Mode
        _isEditMode = State(initialValue: !order.hasLr)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Drag Handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: 0xE2E8F0))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                // ── HEADER (Image 5) ────────────────────────────
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0xDBEAFE))
                            .frame(width: 42, height: 42)

                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: 0x2563EB))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.hasLr && !isEditMode ? "Uploaded Lorry Receipt" : "Upload Lorry Receipt")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))

                        Text("Party: Customer")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: 0x64748B))
                    }

                    Spacer()

                    Button {
                        if !isUploading { dismiss() }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: 0x64748B))
                            .frame(width: 32, height: 32)
                            .background(Color(hex: 0xF1F5F9))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

                Rectangle()
                    .fill(Color(hex: 0xE2E8F0))
                    .frame(height: 1)

                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: 0xDC2626))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                // ── BODY (Image 5) ──────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if order.hasLr && !isEditMode {
                            savedLrView
                        } else {
                            uploadLrForm
                        }
                    }
                    .padding(20)
                }

                Rectangle()
                    .fill(Color(hex: 0xE2E8F0))
                    .frame(height: 1)

                // ── FOOTER ACTIONS (Image 5) ────────────────────
                if isEditMode || !order.hasLr {
                    HStack(spacing: 12) {
                        Button {
                            if isUploading { return }
                            if order.hasLr {
                                // Revert to saved view
                                lrNumber = order.lrNumber ?? ""
                                transporter = order.transporter ?? ""
                                vehicleNumber = order.vehicleNumber ?? ""
                                lrNotes = order.lrNotes ?? ""
                                selectedImageDataUri = nil
                                selectedFileName = order.lrFileName
                                selectedFileSize = order.lrFileSize
                                isEditMode = false
                            } else {
                                dismiss()
                            }
                        } label: {
                            Text(order.hasLr ? "Back" : "Close")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: 0x0F172A))
                                .frame(width: 100)
                                .frame(height: 48)
                                .background(Color.white)
                        }

                        Button {
                            Task { await saveLR() }
                        } label: {
                            HStack(spacing: 6) {
                                if isUploading {
                                    ProgressView().tint(.white)
                                    Text("Saving…")
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save LR Document")
                                }
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(canSave && !isUploading ? Color(hex: 0x2563EB) : Color(hex: 0x93C5FD))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!canSave || isUploading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
            }

            if showCameraPicker {
                CameraCaptureModal(
                    orderNumber: order.displayOrderNumber,
                    customerName: order.customerName ?? "Customer",
                    onImageCaptured: { image in
                        if let data = image.jpegData(compressionQuality: 0.8) {
                            handlePickedImageData(data: data, customFileName: "lr_camera_\(order.displayOrderNumber).jpg")
                        }
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showCameraPicker = false
                        }
                    },
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showCameraPicker = false
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .alert("Delete LR Record?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await deleteLR() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The LR number, transporter details and attached document will be removed from this order.")
        }
        .sheet(isPresented: Binding(
            get: { previewUrl != nil },
            set: { if !$0 { previewUrl = nil } }
        )) {
            if let url = previewUrl {
                PDFPreviewSheet(url: url, title: "Lorry Receipt (LR)")
            }
        }
        .fileImporter(
            isPresented: $showDocPicker,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            handlePickedDocument(result: result)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        handlePickedImageData(data: data)
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        return !lrNumber.trimmingCharacters(in: .whitespaces).isEmpty ||
            selectedImageDataUri != nil ||
            order.hasLrDocument
    }

    // ── UPLOAD LR FORM (Image 5) ───────────────────────────────
    private var uploadLrForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row for Bilty
            HStack {
                Text("SELECT TRANSPORTER BILTY *")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(Color(hex: 0x64748B))
                    .tracking(0.4)

                Spacer()

                Text("PDF, JPG, PNG (MAX 10MB)")
                    .font(.system(size: 10.5))
                    .foregroundColor(Color(hex: 0x94A3B8))
            }

            // 3-Button Picker Row (Image 5)
            HStack(spacing: 8) {
                // Wide Button: Choose Photo / LR Document
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera")
                            .font(.system(size: 14))
                        Text("Choose Photo / LR Document")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: 0x2563EB))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: 0xBFDBFE), lineWidth: 1)
                    )
                }

                // Camera Icon Button
                Button {
                    showCameraPicker = true
                } label: {
                    Image(systemName: "camera")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: 0x2563EB))
                        .frame(width: 46, height: 46)
                        .background(Color(hex: 0xEFF6FF))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: 0xBFDBFE), lineWidth: 1)
                        )
                }

                // Folder Icon Button (for PDF / Files)
                Button {
                    showDocPicker = true
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: 0x2563EB))
                        .frame(width: 46, height: 46)
                        .background(Color(hex: 0xEFF6FF))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: 0xBFDBFE), lineWidth: 1)
                        )
                }
            }

            // File preview card if file selected
            if let fileName = selectedFileName, !fileName.trimmingCharacters(in: .whitespaces).isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .foregroundColor(Color(hex: 0x2563EB))
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(fileName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)
                        Text(selectedFileSize ?? "Attached file")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: 0x64748B))
                    }

                    Spacer()

                    Button {
                        selectedFileName = nil
                        selectedFileSize = nil
                        selectedImageDataUri = nil
                        selectedPhotoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: 0x94A3B8))
                    }
                }
                .padding(12)
                .background(Color(hex: 0xF8FAFC))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            }

            // Field 1: LR / Bilty Number (Optional)
            VStack(alignment: .leading, spacing: 6) {
                Text("LR / Bilty Number (Optional)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x0F172A))

                HStack(spacing: 10) {
                    Text("#")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .frame(width: 20)

                    TextField("RJ-974887", text: $lrNumber)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: 0x0F172A))
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            }
            .padding(.top, 4)

            // Field 2: Transporter / Carrier (Optional)
            VStack(alignment: .leading, spacing: 6) {
                Text("Transporter / Carrier (Optional)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x0F172A))

                HStack(spacing: 10) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .frame(width: 20)

                    TextField("Jaipur golden Transport", text: $transporter)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: 0x0F172A))
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            }

            // Field 3: Vehicle / Truck Number (Optional)
            VStack(alignment: .leading, spacing: 6) {
                Text("Vehicle / Truck Number (Optional)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x0F172A))

                HStack(spacing: 10) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .frame(width: 20)

                    TextField("RJ-01-9849", text: $vehicleNumber)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: 0x0F172A))
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            }

            // Field 4: Dispatch Notes (Optional)
            VStack(alignment: .leading, spacing: 6) {
                Text("Dispatch Notes (Optional)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x0F172A))

                HStack(spacing: 10) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: 0x94A3B8))
                        .frame(width: 20)

                    TextField("Fragile Items - Spare parts intact", text: $lrNotes)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: 0x0F172A))
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
            }
        }
    }

    // ── SAVED LR VIEW ──────────────────────────────────────────
    private var savedLrView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Green Card Header
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(lrGreenBorder, lineWidth: 1))
                            .frame(width: 36, height: 36)
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 16))
                            .foregroundColor(lrGreenText)
                    }

                    Text(order.hasLrDocument ? "LR DOCUMENT ATTACHED" : "LR DETAILS SAVED")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(lrGreenText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(lrGreenBgSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Spacer()

                    Circle()
                        .fill(lrGreenDot)
                        .frame(width: 10, height: 10)
                }

                // If file exists, show file row
                if let fileUrl = order.lrFileUrl, !fileUrl.isEmpty {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: 0xF1F5F9))
                                .frame(width: 48, height: 48)

                            if fileUrl.hasPrefix("data:image") || fileUrl.hasSuffix(".jpg") || fileUrl.hasSuffix(".png") {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: 0x2563EB))
                            } else {
                                Image(systemName: "doc.richtext.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: 0xDC2626))
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(order.lrFileName ?? "lr_document.jpg")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: 0x0F172A))
                                .lineLimit(1)
                            Text(order.lrFileSize?.isEmpty == false ? order.lrFileSize! : "Ready for viewing")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: 0x64748B))
                        }

                        Spacer()

                        Button {
                            openDocument(fileUrl)
                        } label: {
                            Text("View")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: 0x2563EB))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: 0xEFF6FF))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(lrGreenBorder, lineWidth: 1))
                }

                // Details Rows
                VStack(spacing: 8) {
                    savedDetailRow(label: "LR Number", value: order.lrNumber ?? "—", isBold: true)
                    savedDetailRow(label: "Transporter", value: order.transporter ?? "—")
                    savedDetailRow(label: "Vehicle Number", value: order.vehicleNumber ?? "—")
                    if let notes = order.lrNotes, !notes.isEmpty {
                        savedDetailRow(label: "Notes", value: notes)
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(lrGreenBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(lrGreenBorder, lineWidth: 1))

            // Action Buttons: Replace / Delete
            HStack(spacing: 12) {
                Button {
                    isEditMode = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Replace LR File")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0x2563EB))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: 0xEFF6FF))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xBFDBFE), lineWidth: 1))
                }

                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Delete LR")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0xDC2626))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: 0xFEF2F2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xFECACA), lineWidth: 1))
                }
            }
        }
    }

    private func savedDetailRow(label: String, value: String, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0x64748B))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: isBold ? .bold : .medium, design: isBold ? .monospaced : .default))
                .foregroundColor(Color(hex: 0x0F172A))
        }
    }

    // ── FILE HANDLING ──────────────────────────────────────────
    private func handlePickedImageData(data: Data, customFileName: String? = nil) {
        if data.count > 10 * 1024 * 1024 {
            errorMessage = "Image file is too large (max 10 MB)"
            return
        }

        let base64 = data.base64EncodedString()
        self.selectedImageDataUri = "data:image/jpeg;base64,\(base64)"
        self.selectedFileName = customFileName ?? "lr_\(order.displayOrderNumber).jpg"
        self.selectedFileSize = formatFileSize(data.count)
        self.errorMessage = nil
    }

    private func handlePickedDocument(result: Result<[URL], Error>) {
        do {
            guard let selectedUrl = try result.get().first else { return }
            guard selectedUrl.startAccessingSecurityScopedResource() else {
                errorMessage = "Could not access selected document"
                return
            }
            defer { selectedUrl.stopAccessingSecurityScopedResource() }

            let data = try Data(contentsOf: selectedUrl)
            if data.count > 10 * 1024 * 1024 {
                errorMessage = "Document exceeds 10 MB limit"
                return
            }

            let ext = selectedUrl.pathExtension.lowercased()
            let mime = (ext == "pdf") ? "application/pdf" : "image/\(ext)"
            let base64 = data.base64EncodedString()
            self.selectedImageDataUri = "data:\(mime);base64,\(base64)"
            self.selectedFileName = selectedUrl.lastPathComponent
            self.selectedFileSize = formatFileSize(data.count)
            self.errorMessage = nil
        } catch {
            errorMessage = "Failed to load document: \(error.localizedDescription)"
        }
    }

    private func openDocument(_ rawUrl: String) {
        if rawUrl.hasPrefix("data:") {
            guard let commaIdx = rawUrl.firstIndex(of: ",") else { return }
            let meta = String(rawUrl[..<commaIdx])
            let base64Str = String(rawUrl[rawUrl.index(after: commaIdx)...])
            guard let data = Data(base64Encoded: base64Str, options: .ignoreUnknownCharacters) else { return }

            let ext = meta.contains("pdf") ? "pdf" : "jpg"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("LR_\(order.displayOrderNumber).\(ext)")
            try? data.write(to: tempURL)
            self.previewUrl = tempURL
        } else if let remote = URL(string: rawUrl) {
            self.previewUrl = remote
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        return String(format: "%.2f MB", kb / 1024.0)
    }

    // ── SAVE & DELETE ──────────────────────────────────────────
    private func saveLR() async {
        guard let token = SessionManager.shared.session?.token else {
            errorMessage = "Authentication session expired"
            return
        }

        isUploading = true
        errorMessage = nil

        do {
            let targetId = order.targetIdForApi
            let updated = try await OrderService.shared.updateOrderLR(
                token: token,
                id: targetId,
                lrNumber: lrNumber.trimmingCharacters(in: .whitespaces),
                transporter: transporter.trimmingCharacters(in: .whitespaces),
                vehicleNumber: vehicleNumber.trimmingCharacters(in: .whitespaces),
                lrNotes: lrNotes.trimmingCharacters(in: .whitespaces),
                fileDataUri: selectedImageDataUri,
                fileName: selectedFileName,
                fileSize: selectedFileSize
            )

            await MainActor.run {
                self.isUploading = false
                self.onSaved(updated)
                self.dismiss()
            }
        } catch {
            await MainActor.run {
                self.isUploading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteLR() async {
        guard let token = SessionManager.shared.session?.token else { return }
        isUploading = true

        do {
            let targetId = order.targetIdForApi
            let updated = try await OrderService.shared.deleteOrderLR(token: token, id: targetId)
            await MainActor.run {
                self.isUploading = false
                self.onSaved(updated)
                self.dismiss()
            }
        } catch {
            await MainActor.run {
                self.isUploading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

// ============================================================
// ── CAMERA CAPTURE SYSTEM (Native Device & Simulator) ───────
// ============================================================

public struct CameraCaptureModal: View {
    public let orderNumber: String
    public let customerName: String
    public var onImageCaptured: (UIImage) -> Void
    public var onDismiss: () -> Void

    public init(
        orderNumber: String,
        customerName: String,
        onImageCaptured: @escaping (UIImage) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.orderNumber = orderNumber
        self.customerName = customerName
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
            SimulatorCameraScannerView(
                orderNumber: orderNumber,
                customerName: customerName,
                onImageCaptured: { image in
                    onImageCaptured(image)
                },
                onDismiss: {
                    onDismiss()
                }
            )
            .ignoresSafeArea()
        }
    }
}

// ── Native Hardware Camera (Physical iPhone) ─────────────────
public struct UIKitCameraPicker: UIViewControllerRepresentable {
    public var onImageCaptured: (UIImage) -> Void
    public var onCancel: () -> Void

    public init(onImageCaptured: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.onImageCaptured = onImageCaptured
        self.onCancel = onCancel
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: UIKitCameraPicker

        init(_ parent: UIKitCameraPicker) {
            self.parent = parent
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
                parent.onImageCaptured(image)
            } else {
                parent.onCancel()
            }
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}

// ── Camera Scanner Viewfinder (iOS Simulator & Testing) ──────
public struct SimulatorCameraScannerView: View {
    public let orderNumber: String
    public let customerName: String
    public var onImageCaptured: (UIImage) -> Void
    public var onDismiss: () -> Void

    @State private var isFlashOn: Bool = false
    @State private var isCaptured: Bool = false
    @State private var capturedImage: UIImage? = nil
    @State private var showFlashAnimation: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isScanLineMovingDown: Bool = false

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button {
                        isFlashOn.toggle()
                    } label: {
                        Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(isFlashOn ? .yellow : .white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(isCaptured ? "Review Photo" : "Camera (LR Scanner)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Instruction Pill
                HStack(spacing: 6) {
                    Image(systemName: isCaptured ? "checkmark.circle.fill" : "viewfinder")
                        .foregroundColor(isCaptured ? Color(hex: 0x10B981) : Color(hex: 0x38BDF8))
                    Text(isCaptured ? "Photo captured successfully" : "Align LR / Bilty receipt inside frame")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
                .padding(.bottom, 12)

                Spacer(minLength: 0)

                // Viewfinder / Document Area
                ZStack {
                    if let image = capturedImage, isCaptured {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                            .shadow(color: .black.opacity(0.6), radius: 16)
                    } else {
                        liveDocumentViewfinder
                    }
                }
                .frame(maxHeight: .infinity)

                Spacer(minLength: 0)

                // Bottom Control Bar
                bottomControls
                    .padding(.horizontal, 28)
                    .padding(.bottom, 36)
                    .padding(.top, 16)
            }

            // White Flash Animation
            if showFlashAnimation {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.85)
                    .transition(.opacity)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.capturedImage = uiImage
                        self.isCaptured = true
                    }
                }
            }
        }
    }

    // Live Document Viewfinder
    private var liveDocumentViewfinder: some View {
        ZStack {
            // Document Card Simulation
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox.fill")
                        .foregroundColor(Color(hex: 0x2563EB))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("JAIPUR GOLDEN TRANSPORT CO.")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))
                        Text("CONSIGNMENT NOTE / BILTY")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(hex: 0x2563EB))
                    }
                    Spacer()
                    Text("RJ-974887")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: 0xDC2626))
                }

                Divider()

                VStack(alignment: .leading, spacing: 3) {
                    Text("Consignor: Rajputana Automobiles, Kota")
                        .font(.system(size: 9.5))
                        .foregroundColor(Color(hex: 0x475569))
                    Text("Consignee: \(customerName)")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(Color(hex: 0x0F172A))
                    Text("Order Ref: \(orderNumber)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color(hex: 0x64748B))
                }

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("PKGS / GOODS")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(hex: 0x64748B))
                        Text("1 Box / Spare Parts")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(Color(hex: 0x0F172A))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("WEIGHT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(hex: 0x64748B))
                        Text("14.50 KG")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(Color(hex: 0x0F172A))
                    }
                }
                .padding(6)
                .background(Color(hex: 0xF1F5F9))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                // Verification Stamp
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("DISPATCHED & VERIFIED")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: 0x059669))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: 0x059669), lineWidth: 1.5)
                    )
                    .rotationEffect(.degrees(-5))
                    Spacer()
                }
            }
            .padding(14)
            .frame(width: 280, height: 380)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.4), radius: 12)

            // Viewfinder Frame Outline
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.85), lineWidth: 2)
                .frame(width: 296, height: 396)
                .overlay(
                    // Scanning line animation
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x38BDF8).opacity(0), Color(hex: 0x38BDF8), Color(hex: 0x38BDF8).opacity(0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .offset(y: isScanLineMovingDown ? 180 : -180)
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isScanLineMovingDown = true
            }
            if ProcessInfo.processInfo.arguments.contains("-simulateCapture") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    triggerShutter()
                }
            }
        }
    }

    // Bottom Controls
    private var bottomControls: some View {
        HStack {
            if isCaptured {
                // Retake Button
                Button {
                    withAnimation {
                        isCaptured = false
                        capturedImage = nil
                    }
                } label: {
                    Text("Retake")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 48)
                }

                Spacer()

                // Use Photo Button
                Button {
                    if let img = capturedImage {
                        onImageCaptured(img)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Use Photo")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 48)
                    .background(Color(hex: 0x2563EB))
                    .clipShape(Capsule())
                }
            } else {
                // Photos Library Button
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }

                Spacer()

                // Classic Shutter Button
                Button {
                    triggerShutter()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 74, height: 74)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 62, height: 62)
                    }
                }

                Spacer()

                // Camera Flip Button
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }
            }
        }
    }

    private func triggerShutter() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        withAnimation(.easeIn(duration: 0.1)) {
            showFlashAnimation = true
        }

        let rendered = generateBiltyReceiptImage(orderNumber: orderNumber, customerName: customerName)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.15)) {
                showFlashAnimation = false
                capturedImage = rendered
                isCaptured = true
            }
        }
    }
}

// ── Realistic LR / Bilty Document Generator ───────────────────
public func generateBiltyReceiptImage(orderNumber: String, customerName: String) -> UIImage {
    let size = CGSize(width: 800, height: 1100)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
        let context = ctx.cgContext

        // Background
        let paperColor = UIColor(red: 0.98, green: 0.98, blue: 0.96, alpha: 1.0)
        paperColor.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        // Double Border
        let outerRect = CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40)
        context.setStrokeColor(UIColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0).cgColor)
        context.setLineWidth(3.0)
        context.stroke(outerRect)

        let innerRect = outerRect.insetBy(dx: 6, dy: 6)
        context.setLineWidth(1.0)
        context.stroke(innerRect)

        // Header
        let titleStyle = NSMutableParagraphStyle()
        titleStyle.alignment = .center
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 26),
            .foregroundColor: UIColor(red: 0.1, green: 0.2, blue: 0.5, alpha: 1.0),
            .paragraphStyle: titleStyle
        ]
        ("JAIPUR GOLDEN TRANSPORT CO." as NSString).draw(in: CGRect(x: 40, y: 40, width: size.width - 80, height: 35), withAttributes: titleAttrs)

        let subStyle = NSMutableParagraphStyle()
        subStyle.alignment = .center
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: subStyle
        ]
        ("FLEET OWNERS & LEADING TRANSPORTERS | ALL INDIA REGULAR DAILY SERVICE\nRegd. Off: Transport Nagar, Kota (Raj.) | GSTIN: 08AAACJ1234F1Z8" as NSString).draw(in: CGRect(x: 40, y: 75, width: size.width - 80, height: 35), withAttributes: subAttrs)

        // LR Banner
        let bannerRect = CGRect(x: 40, y: 120, width: size.width - 80, height: 32)
        UIColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0).setFill()
        UIBezierPath(roundedRect: bannerRect, cornerRadius: 4).fill()

        let bannerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 15),
            .foregroundColor: UIColor.white,
            .paragraphStyle: titleStyle
        ]
        ("LORRY RECEIPT / BILTY (CONSIGNMENT NOTE)" as NSString).draw(in: CGRect(x: 40, y: 126, width: size.width - 80, height: 24), withAttributes: bannerAttrs)

        // LR No & Date
        let leftStyle = NSMutableParagraphStyle()
        leftStyle.alignment = .left
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0),
            .paragraphStyle: leftStyle
        ]
        let rightStyle = NSMutableParagraphStyle()
        rightStyle.alignment = .right
        let rightAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black,
            .paragraphStyle: rightStyle
        ]

        let lrClean = orderNumber.replacingOccurrences(of: "ORD-", with: "LR-")
        ("Bilty / LR No: \(lrClean)" as NSString).draw(in: CGRect(x: 45, y: 165, width: 350, height: 25), withAttributes: boldAttrs)

        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyyy hh:mm a"
        let dateStr = formatter.string(from: Date())
        ("Date: \(dateStr)" as NSString).draw(in: CGRect(x: size.width - 395, y: 165, width: 350, height: 25), withAttributes: rightAttrs)

        // Divider
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: 40, y: 200))
        context.addLine(to: CGPoint(x: size.width - 40, y: 200))
        context.strokePath()

        // Consignor & Consignee Boxes
        let box1 = CGRect(x: 40, y: 215, width: (size.width - 90)/2, height: 130)
        let box2 = CGRect(x: size.width/2 + 5, y: 215, width: (size.width - 90)/2, height: 130)

        UIColor(white: 0.95, alpha: 1.0).setFill()
        UIBezierPath(roundedRect: box1, cornerRadius: 6).fill()
        UIBezierPath(roundedRect: box2, cornerRadius: 6).fill()

        let labelBold: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 13), .foregroundColor: UIColor.black]
        let labelText: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.darkGray]

        ("CONSIGNOR (FROM):" as NSString).draw(at: CGPoint(x: box1.minX + 10, y: box1.minY + 8), withAttributes: labelBold)
        ("Rajputana Automobiles\nNear City Mall, Transport Hub\nKota, Rajasthan - 324005\nPhone: +91 94141 87654" as NSString).draw(in: CGRect(x: box1.minX + 10, y: box1.minY + 28, width: box1.width - 20, height: 95), withAttributes: labelText)

        ("CONSIGNEE (TO):" as NSString).draw(at: CGPoint(x: box2.minX + 10, y: box2.minY + 8), withAttributes: labelBold)
        ("\(customerName)\nDelivery Destination Hub\nRajasthan, India\nRef Order: \(orderNumber)" as NSString).draw(in: CGRect(x: box2.minX + 10, y: box2.minY + 28, width: box2.width - 20, height: 95), withAttributes: labelText)

        // Transport Details table
        let tableTop: CGFloat = 360
        let tableRect = CGRect(x: 40, y: tableTop, width: size.width - 80, height: 260)
        context.setStrokeColor(UIColor.darkGray.cgColor)
        context.stroke(tableRect)

        // Table Header
        let headerH: CGFloat = 30
        UIColor(white: 0.9, alpha: 1.0).setFill()
        context.fill(CGRect(x: 40, y: tableTop, width: size.width - 80, height: headerH))

        ("PKGS" as NSString).draw(in: CGRect(x: 45, y: tableTop + 7, width: 60, height: 20), withAttributes: labelBold)
        ("DESCRIPTION OF GOODS" as NSString).draw(in: CGRect(x: 120, y: tableTop + 7, width: 280, height: 20), withAttributes: labelBold)
        ("WEIGHT (KG)" as NSString).draw(in: CGRect(x: 420, y: tableTop + 7, width: 120, height: 20), withAttributes: labelBold)
        ("FREIGHT / TO-PAY" as NSString).draw(in: CGRect(x: 580, y: tableTop + 7, width: 150, height: 20), withAttributes: labelBold)

        // Table content
        ("1 Box\nCarton" as NSString).draw(in: CGRect(x: 45, y: tableTop + 45, width: 60, height: 60), withAttributes: labelText)
        ("Automotive Spare Parts\n(Genuine Sealed Components)\nOrder SKU verified" as NSString).draw(in: CGRect(x: 120, y: tableTop + 45, width: 280, height: 80), withAttributes: labelText)
        ("14.50 KG\nActual: 14.5\nCharged: 15.0" as NSString).draw(in: CGRect(x: 420, y: tableTop + 45, width: 120, height: 80), withAttributes: labelText)
        ("PAID\nFreight: ₹350.00\nHandling: ₹50.00\nTotal: ₹400.00" as NSString).draw(in: CGRect(x: 580, y: tableTop + 45, width: 150, height: 80), withAttributes: labelText)

        // Stamp Box
        let stampRect = CGRect(x: 80, y: 680, width: 260, height: 110)
        context.saveGState()
        context.translateBy(x: stampRect.midX, y: stampRect.midY)
        context.rotate(by: -0.1)

        let rotatedRect = CGRect(x: -stampRect.width/2, y: -stampRect.height/2, width: stampRect.width, height: stampRect.height)
        let stampColor = UIColor(red: 0.1, green: 0.55, blue: 0.3, alpha: 0.85)
        context.setStrokeColor(stampColor.cgColor)
        context.setLineWidth(3.0)
        let stampPath = UIBezierPath(roundedRect: rotatedRect, cornerRadius: 8)
        stampPath.stroke()

        let stampStyle = NSMutableParagraphStyle()
        stampStyle.alignment = .center
        let stampAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: stampColor,
            .paragraphStyle: stampStyle
        ]
        ("DISPATCHED & VERIFIED\n★ RECEIVED IN GOOD ORDER ★\nJAIPUR GOLDEN TRANSPORT" as NSString).draw(in: rotatedRect.insetBy(dx: 8, dy: 16), withAttributes: stampAttrs)
        context.restoreGState()

        // Barcode / Notes
        let footerY = size.height - 180
        let noteAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.gray,
            .paragraphStyle: titleStyle
        ]
        ("Truck No: RJ-01-9849  |  Driver Contact: 98290-XXXXX  |  Tracking: LIVE\nTerms: Goods loaded at owner's risk as per standard conditions of carriage.\nSubject to Kota jurisdiction only." as NSString).draw(in: CGRect(x: 40, y: footerY, width: size.width - 80, height: 60), withAttributes: noteAttrs)

        // Signature Line
        ("Authorized Signatory" as NSString).draw(in: CGRect(x: size.width - 240, y: footerY + 50, width: 180, height: 20), withAttributes: labelBold)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: size.width - 240, y: footerY + 45))
        context.addLine(to: CGPoint(x: size.width - 60, y: footerY + 45))
        context.strokePath()
    }
}
