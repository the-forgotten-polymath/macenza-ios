import UIKit
import PDFKit

public final class PDFGeneratorService {
    public static let shared = PDFGeneratorService()

    private init() {}

    /// Renders an HTML string into an A4 vector PDF and saves it to a temporary file URL.
    @MainActor
    public func generatePDF(from html: String, fileName: String = "Document.pdf") -> URL? {
        let printPageRenderer = UIPrintPageRenderer()
        let printFormatter = UIMarkupTextPrintFormatter(markupText: html)
        printPageRenderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)

        // A4 Paper Dimensions in Points (72 dpi): 595.2 x 841.8 pt
        let paperRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let margin: CGFloat = 28.0 // ~10mm margins
        let printableRect = paperRect.insetBy(dx: margin, dy: margin)

        printPageRenderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        printPageRenderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)

        for i in 0..<printPageRenderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            printPageRenderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()

        // Clean filename of unsafe characters
        let safeName = fileName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: " ", with: "_")
        let actualName = safeName.hasSuffix(".pdf") ? safeName : "\(safeName).pdf"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(actualName)
        do {
            try pdfData.write(to: tempURL, options: .atomic)
            return tempURL
        } catch {
            print("PDFGeneratorService: Failed to write PDF to \(tempURL): \(error)")
            return nil
        }
    }
}
