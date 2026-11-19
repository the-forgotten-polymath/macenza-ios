import Foundation

public enum NumberToWordsRupees {
    private static let ones = [
        "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
        "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen",
        "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"
    ]

    private static let tens = [
        "", "", "Twenty", "Thirty", "Forty",
        "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
    ]

    private static func twoDigits(_ n: Int) -> String {
        if n < 20 { return ones[n] }
        let t = tens[n / 10]
        let o = ones[n % 10]
        return o.isEmpty ? t : "\(t) \(o)"
    }

    private static func threeDigits(_ n: Int) -> String {
        let h = n / 100
        let r = n % 100
        let hPart = h > 0 ? "\(ones[h]) Hundred" : ""
        let rPart = r > 0 ? twoDigits(r) : ""
        return [hPart, rPart].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// Converts an amount to Indian-style words, always rounding to whole rupees.
    /// Example: 29476.00 -> "Twenty Nine Thousand Four Hundred Seventy Six Rupees Only"
    public static func convert(_ amount: Double) -> String {
        let whole = Int64(abs(amount).rounded())
        if whole == 0 { return "Zero Rupees Only" }

        let crore = Int(whole / 1_00_00_000)
        let lakh = Int((whole / 1_00_000) % 100)
        let thousand = Int((whole / 1_000) % 100)
        let hundred = Int(whole % 1_000)

        var parts: [String] = []
        if crore > 0 { parts.append("\(threeDigits(crore)) Crore") }
        if lakh > 0 { parts.append("\(threeDigits(lakh)) Lakh") }
        if thousand > 0 { parts.append("\(threeDigits(thousand)) Thousand") }
        if hundred > 0 { parts.append(threeDigits(hundred)) }

        let words = parts.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return "\(words) Rupees Only"
    }
}
