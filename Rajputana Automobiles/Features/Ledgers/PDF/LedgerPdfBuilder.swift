import Foundation

public enum LedgerPdfBuilder {

    public static func buildHtml(for ledger: LedgerResponse, customerName: String) -> String {
        let opening = formatINR2(ledger.openingBalance ?? 0.0)
        let debits = formatINR2(ledger.totalDebits ?? 0.0)
        let credits = formatINR2(ledger.totalCredits ?? 0.0)
        let closing = formatINR2(ledger.closingBalance ?? 0.0)

        let nowFormatter = DateFormatter()
        nowFormatter.locale = Locale(identifier: "en_US")
        nowFormatter.dateFormat = "M/d/yy, h:mm a"
        let nowStr = nowFormatter.string(from: Date())

        let cust = ledger.customer
        let cName = escape(cust?.name?.isEmpty == false ? cust!.name! : (cust?.partyName?.isEmpty == false ? cust!.partyName! : customerName))
        let cCity = escape(cust?.city ?? "Maharashtra 411026")
        let cCode = escape(cust?.code ?? "rajputana-pun-011")
        let cGstin = escape(cust?.gstin ?? "27AAACA9876E1Z2")

        let periodFrom = ledger.periodFrom ?? "2021-04-01"
        let periodTo = ledger.periodTo ?? "2021-05-31"
        let periodShort = "\(shortDate(periodFrom)) - \(shortDate(periodTo))"
        let periodLong = "\(prettyDate(periodFrom)) — \(prettyDate(periodTo))"

        let vouchers = ledger.ledgerVouchers ?? []
        let rowsHtml: String
        if vouchers.isEmpty {
            rowsHtml = """
            <tr><td colspan="6" style="text-align:center;color:#94A3B8;padding:24px;">No ledger transactions found in this period</td></tr>
            """
        } else {
            rowsHtml = vouchers.map { v in
                let isDebit = (v.debit ?? 0.0) > 0.0
                let vType = escape(v.voucherType ?? (isDebit ? "Sales" : "Receipt"))
                let badgeClass = isDebit ? "badge-gst" : "badge-receipt"
                let debitCell = isDebit ? "<td class=\"num debit-val\">\(formatINR2(v.debit ?? 0.0))</td>" : "<td class=\"num dash\">&mdash;</td>"
                let creditCell = !isDebit ? "<td class=\"num credit-val\">\(formatINR2(v.credit ?? 0.0))</td>" : "<td class=\"num dash\">&mdash;</td>"

                return """
                <tr>
                  <td>\(escape(shortDate(v.date ?? "")))</td>
                  <td>\(escape(v.particulars ?? "—"))</td>
                  <td><span class="badge \(badgeClass)">\(vType)</span></td>
                  <td>\(escape(v.voucherNumber))</td>
                  \(debitCell)
                  \(creditCell)
                </tr>
                """
            }.joined(separator: "\n")
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <title>Customer Ledger Statement - \(cName)</title>
        <style>
          @page { size: A4; margin: 10mm; }
          * { box-sizing: border-box; }
          html, body { margin: 0; padding: 0; background: #ffffff; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            color: #0F172A;
            font-size: 11px;
            line-height: 1.35;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
            padding: 8px;
          }
          .header-meta {
            display: flex; justify-content: space-between;
            color: #64748B; font-size: 10px;
            padding-bottom: 8px;
            border-bottom: 1px solid #E2E8F0;
            margin-bottom: 12px;
          }
          .metrics {
            display: grid; grid-template-columns: repeat(4, 1fr);
            gap: 10px;
            padding-bottom: 12px;
            border-bottom: 1px solid #E2E8F0;
            margin-bottom: 16px;
          }
          .metric-box {
            background: #F8FAFC;
            border: 1px solid #E2E8F0;
            border-radius: 8px;
            padding: 10px 12px;
          }
          .metric-label {
            font-size: 8.5px; font-weight: 700;
            text-transform: uppercase; letter-spacing: 0.5px;
            color: #64748B; margin: 0;
          }
          .metric-value { font-size: 16px; font-weight: 800; margin: 4px 0 2px 0; font-family: 'SF Mono', monospace; }
          .metric-footer { font-size: 9px; color: #94A3B8; }
          .opening { color: #0F172A; }
          .debits  { color: #0284C7; }
          .credits { color: #059669; }
          .closing { color: #E11D48; }

          .header-band {
            display: flex; justify-content: space-between;
            align-items: flex-start; margin-bottom: 18px;
          }
          .company-name {
            font-size: 16px; font-weight: 800;
            text-transform: uppercase; letter-spacing: 0.3px;
            margin: 0 0 4px 0; color: #0F172A;
          }
          .company-meta { font-size: 10px; color: #64748B; margin: 2px 0; }
          .customer-statement-label {
            font-size: 10px; font-weight: 800;
            text-transform: uppercase; letter-spacing: 1px;
            color: #0F172A; text-align: right;
          }
          .customer-name {
            font-size: 13.5px; font-weight: 700;
            margin: 4px 0 2px 0; text-align: right;
            color: #0F172A;
          }
          .customer-meta {
            font-size: 10px; color: #64748B;
            margin: 2px 0; text-align: right;
          }
          .customer-period { font-style: italic; }

          table { width: 100%; border-collapse: collapse; margin-bottom: 14px; }
          thead th {
            font-size: 9px; font-weight: 800;
            text-transform: uppercase; letter-spacing: 0.4px;
            color: #475569; background: #F8FAFC;
            padding: 8px 10px; text-align: left;
            border-top: 1px solid #E2E8F0;
            border-bottom: 1px solid #E2E8F0;
          }
          tbody td {
            padding: 8px 10px; font-size: 10.5px;
            border-bottom: 1px solid #F1F5F9;
            vertical-align: middle;
          }
          .num { text-align: right; font-family: 'SF Mono','Courier New',monospace; }
          .debit-val { color: #0F172A; font-weight: 600; }
          .credit-val { color: #059669; font-weight: 700; }
          .dash { color: #CBD5E1; }

          .badge {
            display: inline-block; padding: 2px 6px;
            border-radius: 4px;
            font-size: 8.5px; font-weight: 800;
            text-transform: uppercase; letter-spacing: 0.4px;
            white-space: nowrap;
          }
          .badge-gst     { background: #E0F2FE; color: #0369A1; }
          .badge-receipt { background: #D1FAE5; color: #047857; }

          tfoot td { padding: 8px 10px; font-size: 11px; }
          tfoot .first-total-row td { border-top: 2px solid #0F172A; }
          .total-label { font-weight: 700; color: #0F172A; }
          .closing-row td {
            background: #FEF2F2;
            border-top: 1px solid #FECACA;
            border-bottom: 2px solid #E11D48;
            font-weight: 800;
          }
          .closing-val { color: #E11D48; font-weight: 800; font-family: 'SF Mono', monospace; }
        </style>
        </head>
        <body>

        <div class="header-meta">
          <span>STATEMENT OF ACCOUNTS &bull; CONFIDENTIAL</span>
          <span>Generated on: \(nowStr)</span>
        </div>

        <!-- 4 METRICS GRID -->
        <div class="metrics">
          <div class="metric-box">
            <p class="metric-label">Opening Balance</p>
            <p class="metric-value opening">&#8377;\(opening)</p>
            <p class="metric-footer">As of \(shortDate(periodFrom))</p>
          </div>
          <div class="metric-box">
            <p class="metric-label">Total Debits</p>
            <p class="metric-value debits">&#8377;\(debits)</p>
            <p class="metric-footer">GST Invoices</p>
          </div>
          <div class="metric-box">
            <p class="metric-label">Total Credits</p>
            <p class="metric-value credits">&#8377;\(credits)</p>
            <p class="metric-footer">Payments Received</p>
          </div>
          <div class="metric-box" style="background:#FFF5F5;border-color:#FED7D7;">
            <p class="metric-label" style="color:#C53030;">Closing Balance</p>
            <p class="metric-value closing">&#8377;\(closing)</p>
            <p class="metric-footer" style="color:#E53E3E;">As of \(shortDate(periodTo))</p>
          </div>
        </div>

        <!-- HEADER BAND -->
        <div class="header-band">
          <div>
            <h1 class="company-name">Rajputana Automobiles</h1>
            <p class="company-meta">Central Spares &amp; Distribution Division &bull; Jaipur, Rajasthan</p>
            <p class="company-meta">GSTIN: 27AAACAL2341F1Z5 &bull; Phone: +91 98290 99881</p>
          </div>
          <div>
            <div class="customer-statement-label">Customer Ledger Statement</div>
            <div class="customer-name">\(cName)</div>
            <div class="customer-meta">\(cCity) &bull; \(cCode)</div>
            <div class="customer-meta">GSTIN: \(cGstin)</div>
            <div class="customer-meta customer-period">Period: \(periodLong)</div>
          </div>
        </div>

        <!-- VOUCHER TRANSACTIONS TABLE -->
        <table>
          <thead>
            <tr>
              <th style="width: 12%;">Date</th>
              <th style="width: 40%;">Particulars</th>
              <th style="width: 14%;">Type</th>
              <th style="width: 14%;">Voucher #</th>
              <th style="width: 10%; text-align: right;">Debit (&#8377;)</th>
              <th style="width: 10%; text-align: right;">Credit (&#8377;)</th>
            </tr>
          </thead>
          <tbody>
            \(rowsHtml)
          </tbody>
          <tfoot>
            <tr class="first-total-row">
              <td colspan="4" class="total-label" style="text-align: right;">Current Period Totals:</td>
              <td class="num debit-val" style="font-weight: 700;">&#8377;\(debits)</td>
              <td class="num credit-val" style="font-weight: 700;">&#8377;\(credits)</td>
            </tr>
            <tr class="closing-row">
              <td colspan="4" style="text-align: right; color: #991B1B;">CLOSING BALANCE DUE:</td>
              <td colspan="2" class="num closing-val" style="text-align: right;">&#8377;\(closing) Dr</td>
            </tr>
          </tfoot>
        </table>

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

    private static func shortDate(_ iso: String) -> String {
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        if let d = inFmt.date(from: iso) {
            let outFmt = DateFormatter()
            outFmt.dateFormat = "dd MMM yyyy"
            return outFmt.string(from: d)
        }
        return iso.isEmpty ? "—" : iso
    }

    private static func prettyDate(_ iso: String) -> String {
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        if let d = inFmt.date(from: iso) {
            let outFmt = DateFormatter()
            outFmt.dateFormat = "dd MMMM yyyy"
            return outFmt.string(from: d)
        }
        return iso.isEmpty ? "—" : iso
    }

    private static func escape(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
