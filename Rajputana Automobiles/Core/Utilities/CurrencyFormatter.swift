import Foundation

public enum CurrencyFormatter {
    private static let inrFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    public static func formatINR(_ amount: Double) -> String {
        return inrFormatter.string(from: NSNumber(value: amount)) ?? "₹\(String(format: "%.0f", amount))"
    }

    private static let inrDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    public static func formatINRDecimal(_ amount: Double) -> String {
        return inrDecimalFormatter.string(from: NSNumber(value: amount)) ?? "₹\(String(format: "%.2f", amount))"
    }

    public static func formatLakhs(_ amount: Double) -> String {
        let inLakhs = amount / 100_000.0
        return String(format: "₹%.1fL", inLakhs)
    }

    public static func toLakhsValue(_ amount: Double) -> Double {
        return amount / 100_000.0
    }
}
