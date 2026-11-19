import SwiftUI
import WebKit
import UIKit

public struct TaxInvoiceSheet: View {
    public let invoice: Invoice
    public let customer: CustomerDetailModel?
    public var autoShare: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var htmlContent: String = ""
    @State private var isLoading: Bool = true
    @State private var webView = WKWebView()
    @State private var pdfURLToShare: URL? = nil
    @State private var showShareSheet: Bool = false

    public init(invoice: Invoice, customer: CustomerDetailModel? = nil, autoShare: Bool = false) {
        self.invoice = invoice
        self.customer = customer
        self.autoShare = autoShare
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: 0xF8FAFC).ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Preparing Tax Invoice…")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: 0x64748B))
                    }
                } else {
                    TaxInvoiceWebViewRepresentable(htmlContent: htmlContent, webView: webView)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle("Tax Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))
                    }
                }

                ToolbarItemGroup(placement: .confirmationAction) {
                    Button {
                        printInvoice()
                    } label: {
                        Image(systemName: "printer")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: 0x2563EB))
                    }

                    Button {
                        generateAndSharePDF()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: 0x2563EB))
                    }
                }
            }
            .task {
                await loadInvoiceAndBuildHtml()
                if autoShare {
                    // Small delay to let webview layout before sharing
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    generateAndSharePDF()
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURLToShare {
                    ShareSheetView(activityItems: [url])
                }
            }
        }
    }

    private func loadInvoiceAndBuildHtml() async {
        isLoading = true
        let token = SessionManager.shared.session?.token ?? ""
        var detailInvoice = invoice

        // 1. Try to fetch detailed invoice if items are missing
        if detailInvoice.items == nil || detailInvoice.items?.isEmpty == true {
            let party = detailInvoice.party ?? detailInvoice.customerName ?? customer?.name ?? ""
            let invNum = detailInvoice.invoiceNumber.isEmpty ? (detailInvoice.voucherNumber ?? "") : detailInvoice.invoiceNumber
            if !invNum.isEmpty {
                if let fetched = try? await CustomerService.shared.fetchInvoiceDetail(token: token, invoiceNumber: invNum, party: party) {
                    detailInvoice = fetched
                }
            }
        }

        // 2. Fetch company profile
        var companyInfo = InvoiceCompanyInfo()
        if let profile = try? await SettingsService.shared.fetchCompanyProfile(token: token) {
            companyInfo = InvoiceCompanyInfo(from: profile)
        }

        // 3. Build HTML
        let html = InvoicePdfBuilder.buildTaxInvoiceHtml(for: detailInvoice, company: companyInfo, customer: customer)
        self.htmlContent = html
        self.isLoading = false
    }

    private func printInvoice() {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        let invNo = invoice.invoiceNumber.isEmpty ? (invoice.voucherNumber ?? "Invoice") : invoice.invoiceNumber
        printInfo.jobName = "Tax_Invoice_\(invNo)"
        printController.printInfo = printInfo
        printController.printFormatter = webView.viewPrintFormatter()
        printController.present(animated: true, completionHandler: nil)
    }

    private func generateAndSharePDF() {
        let invNo = (invoice.invoiceNumber.isEmpty ? (invoice.voucherNumber ?? "Invoice") : invoice.invoiceNumber)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")

        if #available(iOS 14.0, *) {
            let pdfConfig = WKPDFConfiguration()
            webView.createPDF(configuration: pdfConfig) { result in
                switch result {
                case .success(let data):
                    saveAndPresentPDF(data: data, fileName: "Tax_Invoice_\(invNo).pdf")
                case .failure:
                    fallbackPrintToPDF(fileName: "Tax_Invoice_\(invNo).pdf")
                }
            }
        } else {
            fallbackPrintToPDF(fileName: "Tax_Invoice_\(invNo).pdf")
        }
    }

    private func fallbackPrintToPDF(fileName: String) {
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)

        // A4 Paper: 595.2 x 841.8 pt
        let paperRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let printableRect = paperRect.insetBy(dx: 20, dy: 20)
        renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()

        saveAndPresentPDF(data: pdfData as Data, fileName: fileName)
    }

    private func saveAndPresentPDF(data: Data, fileName: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: tempURL)
            self.pdfURLToShare = tempURL
            self.showShareSheet = true
        } catch {
            print("Failed to save PDF: \(error)")
        }
    }
}

private struct TaxInvoiceWebViewRepresentable: UIViewRepresentable {
    let htmlContent: String
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.showsHorizontalScrollIndicator = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if !htmlContent.isEmpty {
            uiView.loadHTMLString(htmlContent, baseURL: nil)
        }
    }
}

private struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
