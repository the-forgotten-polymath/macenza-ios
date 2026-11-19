import Foundation

public enum ReceiptVoucherPdfBuilder {

    public static func buildHtml(
        voucher: LedgerVoucher,
        customerName: String,
        customerAddress: String? = nil,
        customerGstin: String? = nil,
        customerPhone: String? = nil,
        company: InvoiceCompanyInfo = InvoiceCompanyInfo()
    ) -> String {
        let voucherNo = escape(voucher.voucherNumber.isEmpty ? "VOUCHER" : voucher.voucherNumber)
        let voucherDate = prettyDate(voucher.date ?? "")
        let cName = escape(customerName)
        let cAddress = escape(customerAddress ?? "Plot 42, Auto Market, Rajasthan")
        let cGstin = escape(customerGstin ?? "27AAACA9876E1Z2")
        let cPhone = escape(customerPhone ?? "+91 98230 11223")

        let receivedAmount = voucher.credit ?? 0.0
        let amountWords = NumberToWordsRupees.convert(receivedAmount)
        let amountFormatted = formatINR2(receivedAmount)
        let particulars = escape(voucher.particulars ?? "Payment Received")

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <title>Receipt Voucher \(voucherNo)</title>
        <style>
          @page { size: A4; margin: 12mm; }
          * { box-sizing: border-box; }
          html, body { margin: 0; padding: 0; background: #FFFFFF; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            color: #0F172A;
            font-size: 11.5px;
            line-height: 1.4;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
            padding: 8px;
          }
          .wrapper {
            border: 1px solid #D8DEE9;
            border-radius: 12px;
            background: #FFFFFF;
            padding: 24px;
          }
          .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            padding-bottom: 14px;
            border-bottom: 1.5px solid #0F172A;
            margin-bottom: 20px;
          }
          .header-left { max-width: 62%; }
          .header-right { text-align: right; }
          .company-name {
            font-size: 21px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            color: #0F172A;
            margin: 0 0 5px 0;
          }
          .company-tagline {
            font-size: 11px;
            color: #475569;
            margin: 0 0 6px 0;
          }
          .company-meta {
            font-size: 11px;
            color: #475569;
            margin: 2px 0;
          }
          .company-meta strong { color: #0F172A; font-weight: 700; }

          .voucher-badge {
            display: inline-block;
            padding: 5px 14px;
            border-radius: 20px;
            background: #ECFDF5;
            border: 1px solid #A7F3D0;
            color: #047857;
            font-size: 11.5px;
            font-weight: 800;
            letter-spacing: 0.5px;
            text-transform: uppercase;
            margin-bottom: 10px;
          }
          .meta-row {
            font-size: 11px;
            color: #475569;
            margin: 3px 0;
          }
          .meta-row .lbl { color: #64748B; }
          .meta-row .val {
            color: #0F172A;
            font-weight: 700;
            font-family: 'SF Mono', 'Courier New', monospace;
            margin-left: 4px;
          }

          .received-box {
            border: 1px solid #D8DEE9;
            border-radius: 10px;
            background: #F8FAFC;
            padding: 16px 18px;
            margin-bottom: 18px;
          }
          .received-label {
            font-size: 10px;
            font-weight: 800;
            color: #2563EB;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 8px;
          }
          .customer-name {
            font-size: 15px;
            font-weight: 800;
            color: #0F172A;
            margin-bottom: 4px;
          }
          .customer-line {
            font-size: 11px;
            color: #475569;
            margin: 2px 0;
          }

          .amount-card {
            border: 1.5px solid #059669;
            border-radius: 10px;
            background: #F0FDF4;
            padding: 18px 20px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          .amount-label {
            font-size: 11px;
            font-weight: 700;
            color: #065F46;
            text-transform: uppercase;
            margin-bottom: 4px;
          }
          .amount-words {
            font-size: 12px;
            font-weight: 600;
            color: #047857;
          }
          .amount-val {
            font-size: 24px;
            font-weight: 800;
            color: #047857;
            font-family: 'SF Mono', monospace;
          }

          .details-table {
            width: 100%;
            border-collapse: collapse;
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            margin-bottom: 24px;
          }
          .details-table td {
            padding: 10px 14px;
            border-bottom: 1px solid #EEF2F7;
            font-size: 11px;
          }
          .details-table tr:last-child td { border-bottom: none; }
          .details-label { width: 30%; color: #64748B; font-weight: 600; }
          .details-val { width: 70%; color: #0F172A; font-weight: 700; }

          .footer-row {
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            margin-top: 30px;
          }
          .signatory-box {
            text-align: center;
            width: 220px;
          }
          .sign-line {
            border-top: 1px dashed #94A3B8;
            margin-bottom: 6px;
          }
          .sign-label {
            font-size: 10px;
            color: #64748B;
            font-weight: 600;
          }
        </style>
        </head>
        <body>
        <div class="wrapper">

          <!-- HEADER -->
          <div class="header">
            <div class="header-left">
              <h1 class="company-name">\(escape(company.name))</h1>
              <p class="company-tagline">\(escape(company.tagline))</p>
              <p class="company-meta">\(escape(company.address))</p>
              <p class="company-meta">
                <strong>GSTIN:</strong> \(escape(company.gstin)) &bull;
                <strong>PAN:</strong> \(escape(company.pan))
              </p>
              <p class="company-meta">
                E-mail: \(escape(company.email)) &bull; Phone: \(escape(company.phone))
              </p>
            </div>
            <div class="header-right">
              <div class="voucher-badge">Official Receipt</div>
              <div class="meta-row"><span class="lbl">Voucher No:</span><span class="val">\(voucherNo)</span></div>
              <div class="meta-row"><span class="lbl">Date:</span><span class="val">\(voucherDate)</span></div>
            </div>
          </div>

          <!-- RECEIVED FROM -->
          <div class="received-box">
            <div class="received-label">Received With Thanks From:</div>
            <div class="customer-name">\(cName)</div>
            <div class="customer-line">\(cAddress)</div>
            <div class="customer-line">GSTIN: \(cGstin) &bull; Phone: \(cPhone)</div>
          </div>

          <!-- AMOUNT CARD -->
          <div class="amount-card">
            <div>
              <div class="amount-label">Amount Received</div>
              <div class="amount-words">\(amountWords)</div>
            </div>
            <div class="amount-val">&#8377;\(amountFormatted)</div>
          </div>

          <!-- DETAILS TABLE -->
          <table class="details-table">
            <tr>
              <td class="details-label">Payment Mode / Head</td>
              <td class="details-val">Bank NEFT / RTGS Transfer</td>
            </tr>
            <tr>
              <td class="details-label">Particulars / Narration</td>
              <td class="details-val">\(particulars)</td>
            </tr>
            <tr>
              <td class="details-label">Settlement Bank</td>
              <td class="details-val">\(escape(company.bankName)) &bull; A/C: \(escape(company.bankAccount))</td>
            </tr>
          </table>

          <!-- FOOTER -->
          <div class="footer-row">
            <div style="font-size: 10px; color: #94A3B8;">
              This is a computer-generated receipt voucher and requires no physical seal.
            </div>
            <div class="signatory-box">
              <div style="font-size: 10.5px; font-weight: 700; margin-bottom: 36px;">For \(escape(company.name))</div>
              <div class="sign-line"></div>
              <div class="sign-label">Authorized Signatory</div>
            </div>
          </div>

        </div>
        </body>
        </html>
        """
    }

    private static func formatINR2(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "en_IN")
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2
        return nf.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private static func prettyDate(_ iso: String) -> String {
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        if let d = inFmt.date(from: iso) {
            let outFmt = DateFormatter()
            outFmt.dateFormat = "dd MMMM yyyy"
            return outFmt.string(from: d)
        }
        return iso.isEmpty ? "Today" : iso
    }

    private static func escape(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
