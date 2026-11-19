import SwiftUI

public enum AppTypography {
    public static let title1 = Font.system(size: 24, weight: .bold)
    public static let title2 = Font.system(size: 20, weight: .bold)
    public static let title3 = Font.system(size: 17, weight: .semibold)
    public static let titleLarge = Font.system(size: 22, weight: .bold)
    public static let titleMedium = Font.system(size: 18, weight: .semibold)
    public static let titleSmall = Font.system(size: 16, weight: .semibold)

    public static let headline = Font.system(size: 15, weight: .bold)
    public static let subheadline = Font.system(size: 14, weight: .medium)
    public static let subheadlineBold = Font.system(size: 14, weight: .bold)

    public static let body = Font.system(size: 14, weight: .regular)
    public static let bodyLarge = Font.system(size: 15, weight: .regular)
    public static let bodyMedium = Font.system(size: 14, weight: .regular)
    public static let bodyMediumBold = Font.system(size: 14, weight: .bold)
    public static let bodySmall = Font.system(size: 13, weight: .regular)

    public static let caption = Font.system(size: 12, weight: .medium)
    public static let captionBold = Font.system(size: 12, weight: .bold)
    public static let captionSmall = Font.system(size: 11, weight: .regular)
    public static let micro = Font.system(size: 10, weight: .semibold)
}
