import SwiftUI
import PDFKit

public struct PDFKitRepresentedView: UIViewRepresentable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemGroupedBackground
        if let doc = PDFDocument(url: url) {
            pdfView.document = doc
        }
        return pdfView
    }

    public func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url, let doc = PDFDocument(url: url) {
            uiView.document = doc
        }
    }
}

public struct PDFPreviewSheet: View {
    public let url: URL
    public let title: String

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet: Bool = false

    public init(url: URL, title: String = "Document Preview") {
        self.url = url
        self.title = title
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                PDFKitRepresentedView(url: url)
                    .edgesIgnoringSafeArea(.bottom)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(LiquidTheme.electricBlue)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: {
                        printDocument()
                    }) {
                        Image(systemName: "printer")
                            .foregroundColor(LiquidTheme.electricBlue)
                    }

                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(LiquidTheme.electricBlue)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityViewController(activityItems: [url])
            }
        }
    }

    private func printDocument() {
        guard UIPrintInteractionController.isPrintingAvailable else { return }
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = title
        printController.printInfo = printInfo
        printController.printingItem = url
        printController.present(animated: true, completionHandler: nil)
    }
}

public struct ActivityViewController: UIViewControllerRepresentable {
    public let activityItems: [Any]
    public let applicationActivities: [UIActivity]? = nil

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
