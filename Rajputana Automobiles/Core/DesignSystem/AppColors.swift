import SwiftUI

public enum AppColors {
    // ── BRAND ──────────────────────────────────────────────────
    public static let primary        = Color(hex: 0x3158D4)
    public static let primaryBack    = Color(hex: 0xEAEAFF)
    public static let primaryDark    = Color(hex: 0x2F5CFF)
    public static let primaryLight   = Color(hex: 0x3D5AFE)
    public static let primaryBg      = Color(hex: 0xEFF3FF)
    public static let primaryBgLight = Color(hex: 0xE9F0FF)

    // ── TEXT ───────────────────────────────────────────────────
    public static let textDark       = Color(hex: 0x172033)
    public static let textBody       = Color(hex: 0x475569)
    public static let textGray       = Color(hex: 0x6F7888)
    public static let textLight      = Color(hex: 0x9AA2B1)
    public static let textMuted      = Color(hex: 0x94A3B8)
    public static let textChipGray   = Color(hex: 0x6B7B94)
    public static let textSlate      = Color(hex: 0x53627A)
    public static let textLabelBlue  = Color(hex: 0x8297B5)
    public static let textIconGray   = Color(hex: 0x91A5C1)

    // ── BACKGROUNDS ────────────────────────────────────────────
    public static let pageBackground    = Color(hex: 0xF4F6F9)
    public static let pageBackgroundAlt = Color(hex: 0xF6F9FF)
    public static let cardBackground    = Color.white
    public static let surfaceGray       = Color(hex: 0xF8FAFC)
    public static let surfaceGrayAlt    = Color(hex: 0xF1F4F8)
    public static let surfaceDivider    = Color(hex: 0xF1F5F9)
    public static let chipBg            = Color(hex: 0xF1F5F9)
    public static let white             = Color.white
    public static let black             = Color.black

    // ── BORDERS / DIVIDERS ─────────────────────────────────────
    public static let border        = Color(hex: 0xE4E8EF)
    public static let borderLight   = Color(hex: 0xE5E9F0)
    public static let borderSheet   = Color(hex: 0xE2E8F0)
    public static let borderFaint   = Color(hex: 0xE8EDF3)
    public static let borderOutline = Color(hex: 0xD8DEE9)
    public static let divider       = Color(hex: 0xF0F3F8)
    public static let dividerLight  = Color(hex: 0xEDF0F5)

    // ── SUCCESS ────────────────────────────────────────────────
    public static let green          = Color(hex: 0x00A875)
    public static let greenAlt       = Color(hex: 0x059669)
    public static let greenDeep      = Color(hex: 0x00856A)
    public static let greenLight     = Color(hex: 0xD6FCED)
    public static let greenLightAlt  = Color(hex: 0xECFDF5)
    public static let greenBorder    = Color(hex: 0xA7F3D0)
    public static let greenSubtle    = Color(hex: 0xE8FBF5)
    public static let paidGreen      = Color(hex: 0x22C55E)

    // ── ERROR ──────────────────────────────────────────────────
    public static let red          = Color(hex: 0xDC2626)
    public static let redDeep      = Color(hex: 0xB42318)
    public static let redLight     = Color(hex: 0xFFFFEFED)
    public static let redLightAlt  = Color(hex: 0xFEF2F2)
    public static let redBorder    = Color(hex: 0xFECACA)
    public static let redSoftBorder = Color(hex: 0xFADBD8)
    public static let redAccent     = Color(hex: 0xEF3340)
    public static let redAccentAlt  = Color(hex: 0xEF4349)

    // ── WARNING ────────────────────────────────────────────────
    public static let amber        = Color(hex: 0xD97706)
    public static let amberLight   = Color(hex: 0xFFFBEB)
    public static let amberBorder  = Color(hex: 0xFDE68A)
    public static let amberBright  = Color(hex: 0xFF9F0A)

    // ── INFO ───────────────────────────────────────────────────
    public static let blue        = Color(hex: 0x2563EB)
    public static let blueSoft    = Color(hex: 0xEFF6FF)
    public static let blueBorder  = Color(hex: 0xBFDBFE)
    public static let blueOutline = Color(hex: 0x3D7EFF)
    public static let blueAccent = Color(hex: 0x2F6BDE)
    public static let primaryBorder = Color(hex: 0xBFDBFE)

    // ── PURPLE ─────────────────────────────────────────────────
    public static let purple      = Color(hex: 0x7C3AED)
    public static let purpleLight = Color(hex: 0xF5F3FF)

    // ── AGING CHART ────────────────────────────────────────────
    public static let agingCurrent = Color(hex: 0x00BE87)
    public static let agingDueSoon = Color(hex: 0xFF9F0A)
    public static let agingOverdue = Color(hex: 0xEF4349)

    // ── ORDER DETAIL SPECIFICS ─────────────────────────────────
    public static let orderBg          = Color(hex: 0xF5F7FB)
    public static let orderCardBg      = Color.white
    public static let orderSurfaceGray = Color(hex: 0xF1F5F9)
    public static let cartCardBg       = Color(hex: 0xF7F9FF)
    public static let orderBorder      = Color(hex: 0xE4E8EF)
    public static let orderDivider     = Color(hex: 0xF0F3F8)
    public static let orderTextDark    = Color(hex: 0x0F172A)
    public static let orderTextBody    = Color(hex: 0x475569)
    public static let orderTextGray    = Color(hex: 0x64748B)
    public static let orderTextMuted   = Color(hex: 0x94A3B8)
    public static let orderPrimary     = Color(hex: 0x2563EB)
    public static let orderPrimaryBg   = Color(hex: 0xEFF4FF)

    // ── STANDARD THEME ALIASES ──────────────────────────────────
    public static let brandPrimary         = primary
    public static let brandSecondary       = Color(hex: 0xF97316) // Vibrant Orange Accent
    public static let background           = pageBackground
    public static let textPrimary          = textDark
    public static let textSecondary        = textBody
    public static let surfaceVariant       = surfaceGray
    public static let navDrawerBackground  = Color(hex: 0x1E293B) // Dark Navy
    public static let greenText            = greenDeep
    public static let greenBadgeBackground = greenLight
    public static let statusRedText        = redDeep
    public static let statusRedBg          = redLight
}

public extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }

    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
