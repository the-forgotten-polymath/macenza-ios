import Foundation

public struct InvoiceCompanyInfo {
    public var name: String = "RAJPUTANA AUTOMOBILES"
    public var tagline: String = ""
    public var address: String = "Ram Bhawan,Kutchery Road,Ajmer"
    public var gstin: String = "08AAPFR6807D1ZZ"
    public var pan: String = ""
    public var state: String = "Rajasthan (08)"
    public var email: String = "rajputanaautomobileajmer@gmail.com"
    public var phone: String = "+917878164096"
    public var bankName: String = "Bank Of Baroda"
    public var bankAccount: String = "12850100000449"
    public var bankIfsc: String = "BARB0RAIAJM"
    public var bankBranch: String = "Railway Campus"
    public var terms: [String] = [
        "Goods once sold will be accepted back only under warranty claim terms.",
        "Payment due immediately upon delivery unless specific credit terms apply.",
        "Subject to Rajasthan Jurisdiction only."
    ]

    public init() {}

    public init(from profile: CompanyProfile?) {
        if let p = profile {
            if !p.name.isEmpty { self.name = p.name }
            if !p.tagline.isEmpty { self.tagline = p.tagline }
            if !p.address.isEmpty { self.address = p.address }
            if !p.gstin.isEmpty { self.gstin = p.gstin }
            if let em = p.email, !em.isEmpty { self.email = em }
            else if !p.supportEmail.isEmpty { self.email = p.supportEmail }
            if !p.phone.isEmpty { self.phone = p.phone }
            if let bName = p.bankName, !bName.isEmpty { self.bankName = bName }
            if let bAcc = p.bankAccount, !bAcc.isEmpty { self.bankAccount = bAcc }
            if let bIfsc = p.bankIfsc, !bIfsc.isEmpty { self.bankIfsc = bIfsc }
            if let bBranch = p.bankBranch, !bBranch.isEmpty { self.bankBranch = bBranch }
            if let panStr = p.pan, !panStr.isEmpty { self.pan = panStr }
        }
    }
}

public enum InvoicePdfBuilder {

    // MARK: - From OrderModel
    public static func buildHtml(for order: OrderModel, company: InvoiceCompanyInfo = InvoiceCompanyInfo()) -> String {
        let invoiceNo = order.displayOrderNumber.replacingOccurrences(of: "ORD-", with: "INV-", options: .caseInsensitive)
            .replacingOccurrences(of: "ORD", with: "INV", options: .caseInsensitive)
        let orderRef = order.displayOrderNumber
        let invoiceDate = prettyDate(order.effectiveDate)
        let placeOfSupply = order.shipping?.state?.isEmpty == false ? order.shipping!.state! : company.state

        let receiverName = escape(order.displayCustomerName.isEmpty ? "Customer" : order.displayCustomerName)
        let receiverAddress = order.shipping?.fullAddress ?? "—"
        let receiverPhone = escape(order.shipping?.phone?.isEmpty == false ? order.shipping!.phone! : "—")
        let receiverGstin = "—"
        let receiverState = escape(order.shipping?.state?.isEmpty == false ? order.shipping!.state! : "—")

        let items = order.items ?? []
        let gstPercent = computeGstPercent(order)

        let rowsHtml: String
        if items.isEmpty {
            rowsHtml = """
            <tr><td colspan="8" style="text-align:center;color:#94A3B8;padding:20px;">No line items</td></tr>
            """
        } else {
            rowsHtml = items.enumerated().map { idx, item in
                let qty = item.effectiveQuantity
                let rate = item.effectiveRate
                let amount = Double(qty) * rate
                let partNo = escape(item.itemCode ?? "—")
                let description = escape(item.displayName)
                return """
                <tr>
                  <td class="col-sn">\(idx + 1)</td>
                  <td class="col-sku mono">\(partNo)</td>
                  <td class="col-desc">\(description)</td>
                  <td class="col-qty num">\(qty)</td>
                  <td class="col-rate num">&#8377;\(formatINR2(rate))</td>
                  <td class="col-disc">&ndash;</td>
                  <td class="col-gst">\(gstPercent)%</td>
                  <td class="col-amt num">&#8377;\(formatINR2(amount))</td>
                </tr>
                """
            }.joined(separator: "\n")
        }

        let subtotal = order.subtotal ?? items.reduce(0.0) { $0 + (Double($1.effectiveQuantity) * $1.effectiveRate) }
        let gst = order.gst ?? (subtotal * Double(gstPercent) / 100.0)
        let total = order.total ?? (subtotal + gst)
        let amountInWords = NumberToWordsRupees.convert(total)

        let termsHtml = company.terms.enumerated().map { idx, term in
            "<div class=\"term-row\"><span class=\"term-num\">\(idx + 1).</span><span>\(escape(term))</span></div>"
        }.joined(separator: "\n")

        return template(
            company: company,
            invoiceNo: invoiceNo,
            orderRef: orderRef,
            invoiceDate: invoiceDate,
            placeOfSupply: placeOfSupply,
            receiverName: receiverName,
            receiverAddress: receiverAddress,
            receiverPhone: receiverPhone,
            receiverGstin: receiverGstin,
            receiverState: receiverState,
            rowsHtml: rowsHtml,
            amountInWords: amountInWords,
            subtotal: subtotal,
            gstPercent: gstPercent,
            gst: gst,
            total: total,
            termsHtml: termsHtml
        )
    }

    // MARK: - Dedicated Tax Invoice (Image 4 Match)
    public static func buildHtml(
        for invoice: Invoice,
        company: InvoiceCompanyInfo = InvoiceCompanyInfo(),
        customerName: String? = nil,
        customerGstin: String? = nil,
        customerAddress: String? = nil,
        customerPhone: String? = nil
    ) -> String {
        let cust = CustomerDetailModel(
            code: invoice.customerCode ?? "",
            name: customerName ?? invoice.customerName ?? invoice.party ?? "Customer",
            address: customerAddress ?? invoice.buyerAddress,
            phone: customerPhone,
            gstin: customerGstin ?? invoice.buyerGstin
        )
        return buildTaxInvoiceHtml(for: invoice, company: company, customer: cust)
    }

    public static func buildTaxInvoiceHtml(
        for invoice: Invoice,
        company: InvoiceCompanyInfo = InvoiceCompanyInfo(),
        customer: CustomerDetailModel? = nil
    ) -> String {
        let invoiceNo = escape(invoice.invoiceNumber.isEmpty ? (invoice.voucherNumber ?? "INV") : invoice.invoiceNumber)
        let invoiceDate = prettyDate(invoice.date ?? "")
        let placeOfSupply = escape(invoice.placeOfSupply ?? "Rajasthan")

        let receiverName = escape(customer?.name ?? invoice.customerName ?? invoice.party ?? "13 Traders, Beawar")
        let rawAddr = customer?.fullAddress ?? invoice.buyerAddress ?? "Ajmeri Gate,, Beawar"
        let receiverAddress = escape(rawAddr)
        let receiverState = escape(customer?.state ?? invoice.stateName ?? "Rajasthan")

        let items = invoice.items ?? []
        let rowsHtml: String
        if items.isEmpty {
            rowsHtml = """
            <tr>
              <td class="col-sn">1</td>
              <td class="col-sku mono">AUTO-SPARE</td>
              <td class="col-desc">Spare Parts &amp; Components as per Invoice \(invoiceNo)</td>
              <td class="col-qty num">1</td>
              <td class="col-rate num">&#8377;\(formatINR2(invoice.effectiveAmount / 1.18))</td>
              <td class="col-disc">&ndash;</td>
              <td class="col-amt num">&#8377;\(formatINR2(invoice.effectiveAmount / 1.18))</td>
            </tr>
            """
        } else {
            rowsHtml = items.enumerated().map { idx, item in
                let qty = item.qty ?? 1
                let rate = item.rate ?? 0.0
                let amount = item.amount ?? (Double(qty) * rate)
                let partNo = escape((item.partNo?.isEmpty == false ? item.partNo : nil) ?? "—")
                let description = escape(item.description ?? "Spare Part")
                let disc = escape(item.discount ?? "—")
                return """
                <tr>
                  <td class="col-sn">\(idx + 1)</td>
                  <td class="col-sku mono">\(partNo)</td>
                  <td class="col-desc">\(description)</td>
                  <td class="col-qty num">\(qty)</td>
                  <td class="col-rate num">&#8377;\(formatINRAuto(rate))</td>
                  <td class="col-disc">\(disc)</td>
                  <td class="col-amt num">&#8377;\(formatINR2(amount))</td>
                </tr>
                """
            }.joined(separator: "\n")
        }

        let total = invoice.grandTotal ?? invoice.effectiveAmount
        let subtotal = invoice.subtotal ?? (total / 1.18)
        let cgst = invoice.cgst ?? (invoice.taxAmount != nil ? invoice.taxAmount! / 2.0 : (total - subtotal) / 2.0)
        let sgst = invoice.sgst ?? (invoice.taxAmount != nil ? invoice.taxAmount! / 2.0 : (total - subtotal) / 2.0)
        let amountInWords = NumberToWordsRupees.convert(total)

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <title>Tax Invoice \(invoiceNo)</title>
        <style>
          @page { size: A4; margin: 8mm; }
          * { box-sizing: border-box; }
          html, body { margin: 0; padding: 0; background: #FFFFFF; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            color: #0F172A;
            font-size: 11px;
            line-height: 1.4;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
            padding: 8px;
          }
          .wrapper {
            border: 1px solid #D8DEE9;
            border-radius: 12px;
            background: #FAFBFD;
            padding: 18px;
          }
          .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            padding-bottom: 14px;
            border-bottom: 1.5px solid #0F172A;
            margin-bottom: 14px;
          }
          .header-left { max-width: 62%; }
          .header-right { text-align: right; }
          .company-name {
            font-size: 20px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.3px;
            margin: 0 0 4px 0;
            color: #0F172A;
          }
          .company-meta {
            font-size: 10.5px;
            color: #475569;
            margin: 2px 0;
          }
          .company-meta strong { color: #0F172A; }
          .tax-invoice-title {
            font-size: 20px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin: 0 0 8px 0;
            color: #0F172A;
          }
          .meta-row {
            font-size: 10.5px;
            color: #475569;
            margin: 3px 0;
            display: flex;
            justify-content: flex-end;
            gap: 6px;
          }
          .meta-label { color: #64748B; }
          .meta-value {
            font-weight: 700;
            color: #0F172A;
            font-family: Arial, sans-serif !important;
          }
          .parties {
            display: flex;
            gap: 10px;
            margin-bottom: 14px;
          }
          .party-box {
            flex: 1;
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            background: #FFFFFF;
            padding: 12px 14px;
          }
          .party-title {
            font-size: 10px;
            font-weight: 800;
            color: #2563EB;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            margin-bottom: 8px;
          }
          .party-name {
            font-size: 13px;
            font-weight: 800;
            color: #0F172A;
            margin: 0 0 4px 0;
          }
          .party-line {
            font-size: 10.5px;
            color: #475569;
            margin: 2px 0;
          }
          .party-line .lbl { color: #64748B; }
          .party-line .val { color: #0F172A; font-weight: 600; }

          .items-table {
            width: 100%;
            border-collapse: collapse;
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            overflow: hidden;
            margin-bottom: 14px;
            background: #FFFFFF;
            table-layout: fixed;
          }
          .items-table thead th {
            font-size: 9.5px;
            font-weight: 800;
            color: #475569;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            background: #F1F5F9;
            padding: 8px 8px;
            text-align: left;
            border-bottom: 1px solid #D8DEE9;
            border-right: 1px solid #D8DEE9;
            vertical-align: middle;
          }
          .items-table thead th:last-child { border-right: none; }
          .items-table tbody td {
            font-size: 10.5px;
            color: #0F172A;
            padding: 9px 8px;
            border-bottom: 1px solid #EEF2F7;
            border-right: 1px solid #D8DEE9;
            vertical-align: middle;
          }
          .items-table tbody td:last-child { border-right: none; }
          .items-table tbody tr:last-child td { border-bottom: none; }
          
          .col-sn { width: 5%; text-align: center; }
          .col-sku { width: 19%; text-align: left; font-family: Arial, sans-serif !important; font-weight: 600; }
          .col-desc { width: 33%; text-align: left; }
          .col-qty { width: 8%; text-align: center !important; font-family: Arial, sans-serif !important; font-weight: 600; }
          .col-rate { width: 11%; text-align: right !important; font-family: Arial, sans-serif !important; font-weight: 600; }
          .col-disc { width: 10%; text-align: center !important; font-family: Arial, sans-serif !important; font-weight: 600; }
          .col-amt { width: 14%; text-align: right !important; font-family: Arial, sans-serif !important; font-weight: 600; }

          .bottom-row {
            display: flex;
            gap: 10px;
            margin-bottom: 10px;
            align-items: flex-start;
          }
          .bottom-left { flex: 1.15; }
          .bottom-right { flex: 1; }

          .amount-words-box {
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            background: #FFFFFF;
            padding: 12px 14px;
            margin-bottom: 10px;
          }
          .amount-words-label {
            font-size: 9.5px;
            font-weight: 800;
            color: #64748B;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            margin-bottom: 6px;
          }
          .amount-words-value {
            font-size: 11.5px;
            font-weight: 700;
            color: #0F172A;
          }

          .bank-box {
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            background: #FFFFFF;
            padding: 12px 14px;
          }
          .bank-title {
            font-size: 9.5px;
            font-weight: 800;
            color: #2563EB;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            margin-bottom: 6px;
          }
          .bank-line {
            font-size: 10.5px;
            color: #475569;
            margin: 3px 0;
          }
          .bank-line strong { color: #0F172A; }

          .totals-box {
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            background: #FFFFFF;
            padding: 12px 14px;
          }
          .totals-row {
            display: flex;
            justify-content: space-between;
            padding: 5px 0;
            font-size: 11px;
          }
          .totals-row .lbl { color: #64748B; }
          .totals-row .val {
            font-family: Arial, sans-serif !important;
            font-weight: 600;
            color: #0F172A;
          }
          .totals-divider {
            border-top: 1.5px solid #0F172A;
            margin: 6px 0;
          }
          .grand-total {
            font-size: 12.5px;
            font-weight: 800;
            color: #0F172A;
            display: flex;
            justify-content: space-between;
            padding-top: 8px;
          }
          .grand-total .val {
            font-family: Arial, sans-serif !important;
            font-weight: 800;
            color: #0F172A;
          }

          .signatory-box {
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            background: #FFFFFF;
            padding: 12px 14px;
            margin-top: 10px;
            text-align: center;
            min-height: 70px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
          }
          .signatory-title {
            font-size: 10px;
            font-weight: 800;
            color: #0F172A;
            text-transform: uppercase;
            letter-spacing: 0.4px;
          }
          .signatory-line {
            border-top: 1px dashed #94A3B8;
            margin: 26px 20px 4px 20px;
          }
          .signatory-label {
            font-size: 9.5px;
            color: #64748B;
          }
        </style>
        </head>
        <body>
        <div class="wrapper">

          <!-- HEADER -->
          <div class="header">
            <div class="header-left">
              <h1 class="company-name">\(escape(company.name))</h1>
              <p class="company-meta">\(escape(company.address))</p>
              <p class="company-meta">
                <strong>GSTIN:</strong> \(escape(company.gstin)) &nbsp;
                <strong>State:</strong> \(escape(company.state))
              </p>
              <p class="company-meta">
                E-mail: \(escape(company.email)) &nbsp;&bull;&nbsp;
                Phone: \(escape(company.phone))
              </p>
            </div>
            <div class="header-right">
              <h2 class="tax-invoice-title">TAX INVOICE</h2>
              <div class="meta-row">
                <span class="meta-label">Invoice No:</span>
                <span class="meta-value">\(escape(invoiceNo))</span>
              </div>
              <div class="meta-row">
                <span class="meta-label">Invoice Date:</span>
                <span class="meta-value">\(invoiceDate)</span>
              </div>
              <div class="meta-row">
                <span class="meta-label">Place of Supply:</span>
                <span class="meta-value">\(escape(placeOfSupply))</span>
              </div>
            </div>
          </div>

          <!-- RECEIVER / CONSIGNEE -->
          <div class="parties">
            <div class="party-box">
              <div class="party-title">&bull; DETAILS OF RECEIVER (BILLED TO):</div>
              <p class="party-name">\(receiverName)</p>
              <p class="party-line">\(receiverAddress)</p>
              <p class="party-line">
                <span class="lbl">State Name:</span>
                <span class="val">\(receiverState)</span>
              </p>
            </div>
            <div class="party-box">
              <div class="party-title">&bull; DETAILS OF CONSIGNEE (SHIPPED TO):</div>
              <p class="party-name">\(receiverName)</p>
              <p class="party-line">\(receiverAddress)</p>
              <p class="party-line">
                <span class="lbl">State Name:</span>
                <span class="val">\(receiverState)</span>
              </p>
            </div>
          </div>

          <!-- ITEMS TABLE -->
          <table class="items-table">
            <thead>
              <tr>
                <th class="col-sn">#</th>
                <th class="col-sku">PART NO / SKU</th>
                <th class="col-desc">DESCRIPTION OF GOODS</th>
                <th class="col-qty num">QTY</th>
                <th class="col-rate num">RATE (&#8377;)</th>
                <th class="col-disc">DISC.</th>
                <th class="col-amt num">AMOUNT (&#8377;)</th>
              </tr>
            </thead>
            <tbody>
              \(rowsHtml)
            </tbody>
          </table>

          <!-- BOTTOM ROW -->
          <div class="bottom-row">
            <div class="bottom-left">
              <div class="amount-words-box">
                <div class="amount-words-label">INVOICE AMOUNT IN WORDS:</div>
                <div class="amount-words-value">\(amountInWords)</div>
              </div>
              <div class="bank-box">
                <div class="bank-title">BANK SETTLEMENT &amp; NEFT DETAILS:</div>
                <div class="bank-line">
                  Bank Name: <strong>\(escape(company.bankName))</strong> &bull;
                  A/C No: <strong>\(escape(company.bankAccount))</strong>
                </div>
                <div class="bank-line">
                  IFSC Code: <strong>\(escape(company.bankIfsc))</strong> &bull;
                  Branch: <strong>\(escape(company.bankBranch))</strong>
                </div>
              </div>
            </div>
            <div class="bottom-right">
              <div class="totals-box">
                <div class="totals-row">
                  <span class="lbl">Subtotal (Taxable Value):</span>
                  <span class="val">&#8377;\(formatINR2(subtotal))</span>
                </div>
                <div class="totals-row">
                  <span class="lbl">Central GST (CGST):</span>
                  <span class="val">&#8377;\(formatINR2(cgst))</span>
                </div>
                <div class="totals-row">
                  <span class="lbl">State GST (SGST):</span>
                  <span class="val">&#8377;\(formatINR2(sgst))</span>
                </div>
                <div class="totals-divider"></div>
                <div class="grand-total">
                  <span>GRAND TOTAL (&#8377;):</span>
                  <span class="val">&#8377;\(formatINRAuto(total))</span>
                </div>
              </div>
              <div class="signatory-box">
                <div class="signatory-title">FOR \(escape(company.name))</div>
                <div class="signatory-line"></div>
                <div class="signatory-label">Authorized Signatory</div>
              </div>
            </div>
          </div>

        </div>
        </body>
        </html>
        """
    }

    // MARK: - Template String
    private static func template(
        company: InvoiceCompanyInfo,
        invoiceNo: String,
        orderRef: String,
        invoiceDate: String,
        placeOfSupply: String,
        receiverName: String,
        receiverAddress: String,
        receiverPhone: String,
        receiverGstin: String,
        receiverState: String,
        rowsHtml: String,
        amountInWords: String,
        subtotal: Double,
        gstPercent: Int,
        gst: Double,
        total: Double,
        termsHtml: String
    ) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <title>Tax Invoice \(invoiceNo)</title>
        <style>
          @page { size: A4; margin: 8mm; }
          * { box-sizing: border-box; }
          html, body { margin: 0; padding: 0; background: #FFFFFF; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            color: #0F172A;
            font-size: 11px;
            line-height: 1.4;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
            padding: 8px;
          }
          .wrapper {
            border: 1px solid #D8DEE9;
            border-radius: 12px;
            background: #FAFBFD;
            padding: 18px;
          }
          .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            padding-bottom: 14px;
            border-bottom: 1.5px solid #0F172A;
            margin-bottom: 14px;
          }
          .header-left { max-width: 62%; }
          .header-right { text-align: right; }
          .company-name {
            font-size: 20px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.3px;
            margin: 0 0 4px 0;
            color: #0F172A;
          }
          .company-tagline {
            font-size: 10.5px;
            color: #475569;
            margin: 0 0 6px 0;
          }
          .company-meta {
            font-size: 10.5px;
            color: #475569;
            margin: 2px 0;
          }
          .company-meta strong { color: #0F172A; }
          .tax-invoice-title {
            font-size: 20px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin: 0 0 8px 0;
            color: #0F172A;
          }
          .meta-row {
            font-size: 10.5px;
            color: #475569;
            margin: 3px 0;
            display: flex;
            justify-content: flex-end;
            gap: 6px;
          }
          .meta-label { color: #64748B; }
          .meta-value {
            font-weight: 700;
            color: #0F172A;
            font-family: 'SF Mono', 'Courier New', monospace;
          }
          .parties {
            display: flex;
            gap: 10px;
            margin-bottom: 14px;
          }
          .party-box {
            flex: 1;
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            background: #FFFFFF;
            padding: 12px 14px;
          }
          .party-title {
            font-size: 10px;
            font-weight: 800;
            color: #2563EB;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 6px;
          }
          .party-name {
            font-size: 13px;
            font-weight: 800;
            color: #0F172A;
            margin: 0 0 4px 0;
          }
          .party-line {
            font-size: 10.5px;
            color: #475569;
            margin: 2px 0;
          }
          .party-line .lbl { color: #64748B; }
          .party-line .val { color: #0F172A; font-weight: 600; }
          .party-phone .val { color: #2563EB; font-weight: 700; }

          .items-table {
            width: 100%;
            border-collapse: collapse;
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            overflow: hidden;
            margin-bottom: 14px;
            background: #FFFFFF;
          }
          .items-table thead th {
            font-size: 9.5px;
            font-weight: 800;
            color: #475569;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            background: #F1F5F9;
            padding: 8px 8px;
            text-align: left;
            border-bottom: 1px solid #D8DEE9;
          }
          .items-table tbody td {
            font-size: 10.5px;
            color: #0F172A;
            padding: 9px 8px;
            border-bottom: 1px solid #EEF2F7;
            vertical-align: top;
          }
          .items-table tbody tr:last-child td { border-bottom: none; }
          .num { text-align: right; font-family: 'SF Mono', 'Courier New', monospace; font-weight: 600; }
          .mono { font-family: 'SF Mono', 'Courier New', monospace; font-weight: 700; font-size: 10px; }
          .col-sn { width: 4%; text-align: center; }
          .col-sku { width: 17%; }
          .col-desc { width: 34%; }
          .col-qty { width: 6%; text-align: right; }
          .col-rate { width: 11%; text-align: right; }
          .col-disc { width: 6%; text-align: center; }
          .col-gst { width: 7%; text-align: center; }
          .col-amt { width: 15%; text-align: right; }

          .bottom-row {
            display: flex;
            gap: 10px;
            margin-bottom: 10px;
          }
          .bottom-left { flex: 1.15; }
          .bottom-right { flex: 1; }

          .amount-words-box {
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            background: #FFFFFF;
            padding: 12px 14px;
            margin-bottom: 10px;
          }
          .amount-words-label {
            font-size: 9.5px;
            font-weight: 800;
            color: #64748B;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            margin-bottom: 6px;
          }
          .amount-words-value {
            font-size: 11.5px;
            font-weight: 700;
            color: #0F172A;
          }

          .totals-box {
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            background: #FFFFFF;
            padding: 12px 14px;
          }
          .totals-row {
            display: flex;
            justify-content: space-between;
            padding: 5px 0;
            font-size: 11px;
          }
          .totals-row .lbl { color: #64748B; }
          .totals-row .val {
            font-family: 'SF Mono', 'Courier New', monospace;
            font-weight: 700;
            color: #0F172A;
          }
          .totals-divider {
            border-top: 1.5px solid #0F172A;
            margin: 6px 0;
          }
          .grand-total {
            font-size: 13px;
            font-weight: 800;
            color: #0F172A;
            display: flex;
            justify-content: space-between;
            padding-top: 8px;
          }
          .grand-total .val {
            font-family: 'SF Mono', 'Courier New', monospace;
            font-weight: 800;
            color: #0F172A;
          }

          .bank-box {
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            background: #FFFFFF;
            padding: 12px 14px;
          }
          .bank-title {
            font-size: 9.5px;
            font-weight: 800;
            color: #2563EB;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            margin-bottom: 6px;
          }
          .bank-line {
            font-size: 10.5px;
            color: #475569;
            margin: 3px 0;
          }
          .bank-line strong { color: #0F172A; }

          .signatory-box {
            border: 1px solid #D8DEE9;
            border-radius: 8px;
            background: #FFFFFF;
            padding: 12px 14px;
            margin-top: 10px;
            text-align: center;
            min-height: 70px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
          }
          .signatory-title {
            font-size: 10px;
            font-weight: 800;
            color: #0F172A;
            text-transform: uppercase;
            letter-spacing: 0.4px;
          }
          .signatory-line {
            border-top: 1px dashed #94A3B8;
            margin: 26px 20px 4px 20px;
          }
          .signatory-label {
            font-size: 9.5px;
            color: #64748B;
          }

          .terms-box {
            margin-top: 12px;
            padding-top: 12px;
            border-top: 1px solid #E2E8F0;
          }
          .terms-title {
            font-size: 10px;
            font-weight: 800;
            color: #0F172A;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            margin-bottom: 6px;
          }
          .term-row {
            display: flex;
            gap: 6px;
            font-size: 10px;
            color: #475569;
            margin: 3px 0;
          }
          .term-num { color: #64748B; min-width: 12px; }
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
                <strong>GSTIN:</strong> \(escape(company.gstin)) &nbsp;
                <strong>PAN:</strong> \(escape(company.pan)) &nbsp;
                <strong>State:</strong> \(escape(company.state))
              </p>
              <p class="company-meta">
                E-mail: \(escape(company.email)) &nbsp;&bull;&nbsp;
                Phone: \(escape(company.phone))
              </p>
            </div>
            <div class="header-right">
              <h2 class="tax-invoice-title">Tax Invoice</h2>
              <div class="meta-row">
                <span class="meta-label">Invoice No:</span>
                <span class="meta-value">\(escape(invoiceNo))</span>
              </div>
              <div class="meta-row">
                <span class="meta-label">Order Ref:</span>
                <span class="meta-value">\(escape(orderRef))</span>
              </div>
              <div class="meta-row">
                <span class="meta-label">Invoice Date:</span>
                <span class="meta-value">\(invoiceDate)</span>
              </div>
              <div class="meta-row">
                <span class="meta-label">Place of Supply:</span>
                <span class="meta-value">\(escape(placeOfSupply))</span>
              </div>
            </div>
          </div>

          <!-- RECEIVER / CONSIGNEE -->
          <div class="parties">
            <div class="party-box">
              <div class="party-title">Details of Receiver (Billed To):</div>
              <p class="party-name">\(receiverName)</p>
              <p class="party-line">\(receiverAddress)</p>
              <p class="party-line party-phone">
                <span class="lbl">Phone:</span>
                <span class="val">\(receiverPhone)</span>
              </p>
              <p class="party-line">
                <span class="lbl">GSTIN / UIN:</span>
                <span class="val">\(receiverGstin)</span>
              </p>
              <p class="party-line">
                <span class="lbl">State Name:</span>
                <span class="val">\(receiverState)</span>
              </p>
            </div>
            <div class="party-box">
              <div class="party-title">Details of Consignee (Shipped To):</div>
              <p class="party-name">\(receiverName)</p>
              <p class="party-line">\(receiverAddress)</p>
              <p class="party-line party-phone">
                <span class="lbl">Contact:</span>
                <span class="val">\(receiverPhone)</span>
              </p>
              <p class="party-line">
                <span class="lbl">Dispatch Mode:</span>
                <span class="val">Transporter Road Carrier / Surface Express</span>
              </p>
            </div>
          </div>

          <!-- ITEMS TABLE -->
          <table class="items-table">
            <thead>
              <tr>
                <th class="col-sn">#</th>
                <th class="col-sku">Part No / SKU</th>
                <th class="col-desc">Description of Goods</th>
                <th class="col-qty num">Qty</th>
                <th class="col-rate num">Rate (&#8377;)</th>
                <th class="col-disc">Disc.</th>
                <th class="col-gst">GST %</th>
                <th class="col-amt num">Amount (&#8377;)</th>
              </tr>
            </thead>
            <tbody>
              \(rowsHtml)
            </tbody>
          </table>

          <!-- BOTTOM ROW -->
          <div class="bottom-row">
            <div class="bottom-left">
              <div class="amount-words-box">
                <div class="amount-words-label">Invoice Amount in Words:</div>
                <div class="amount-words-value">\(amountInWords)</div>
              </div>
              <div class="bank-box">
                <div class="bank-title">Bank Settlement &amp; NEFT Details:</div>
                <div class="bank-line">
                  Bank Name: <strong>\(escape(company.bankName))</strong> &bull;
                  A/C No: <strong>\(escape(company.bankAccount))</strong>
                </div>
                <div class="bank-line">
                  IFSC Code: <strong>\(escape(company.bankIfsc))</strong> &bull;
                  Branch: <strong>\(escape(company.bankBranch))</strong>
                </div>
              </div>
            </div>
            <div class="bottom-right">
              <div class="totals-box">
                <div class="totals-row">
                  <span class="lbl">Subtotal (Taxable Value):</span>
                  <span class="val">&#8377;\(formatINR2(subtotal))</span>
                </div>
                <div class="totals-row">
                  <span class="lbl">Integrated GST (IGST @ \(gstPercent)%):</span>
                  <span class="val">&#8377;\(formatINR2(gst))</span>
                </div>
                <div class="totals-divider"></div>
                <div class="grand-total">
                  <span>GRAND TOTAL (&#8377;):</span>
                  <span class="val">&#8377;\(formatINRAuto(total))</span>
                </div>
              </div>
              <div class="signatory-box">
                <div class="signatory-title">For \(escape(company.name))</div>
                <div class="signatory-line"></div>
                <div class="signatory-label">Authorized Signatory</div>
              </div>
            </div>
          </div>

          <!-- TERMS -->
          <div class="terms-box">
            <div class="terms-title">Terms &amp; Conditions:</div>
            \(termsHtml)
          </div>

        </div>
        </body>
        </html>
        """
    }

    // MARK: - Helpers
    private static func computeGstPercent(_ order: OrderModel) -> Int {
        let subtotal = order.subtotal ?? 0.0
        let gst = order.gst ?? 0.0
        if subtotal <= 0.0 { return 18 }
        let pct = Int((gst / subtotal * 100.0).rounded())
        return min(max(pct, 0), 99)
    }

    private static func prettyDate(_ iso: String) -> String {
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        if let d = inFmt.date(from: iso) {
            let outFmt = DateFormatter()
            outFmt.dateFormat = "dd MMM yyyy"
            return outFmt.string(from: d)
        }
        return iso.isEmpty ? "Today" : iso
    }

    private static func formatINR2(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "en_IN")
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2
        return nf.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private static func formatINRAuto(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "en_IN")
        if floor(value) == value {
            nf.minimumFractionDigits = 0
            nf.maximumFractionDigits = 0
        } else {
            nf.minimumFractionDigits = 2
            nf.maximumFractionDigits = 2
        }
        return nf.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private static func escape(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
