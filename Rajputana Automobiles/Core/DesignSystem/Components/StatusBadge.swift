import SwiftUI

public struct StatusBadge: View {
    public let text: String
    public var style: BadgeStyle = .neutral

    public enum BadgeStyle {
        case success
        case warning
        case danger
        case info
        case neutral
        case custom(fg: Color, bg: Color, border: Color)

        var fgColor: Color {
            switch self {
            case .success: return AppColors.greenDeep
            case .warning: return AppColors.amber
            case .danger: return AppColors.redDeep
            case .info: return AppColors.blueAccent
            case .neutral: return AppColors.textBody
            case .custom(let fg, _, _): return fg
            }
        }

        var bgColor: Color {
            switch self {
            case .success: return AppColors.greenLightAlt
            case .warning: return AppColors.amberLight
            case .danger: return AppColors.redLightAlt
            case .info: return AppColors.blueSoft
            case .neutral: return AppColors.surfaceGray
            case .custom(_, let bg, _): return bg
            }
        }

        var borderColor: Color {
            switch self {
            case .success: return AppColors.greenBorder
            case .warning: return AppColors.amberBorder
            case .danger: return AppColors.redBorder
            case .info: return AppColors.blueBorder
            case .neutral: return AppColors.border
            case .custom(_, _, let border): return border
            }
        }
    }

    public init(text: String, style: BadgeStyle = .neutral) {
        self.text = text
        self.style = style
    }

    public init(status: String) {
        self.text = status
        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "approved", "synced", "delivered", "active", "paid", "lr ready":
            self.style = .success
        case "confirmed", "pending", "draft", "in review", "dispatched":
            self.style = .warning
        case "rejected", "cancelled", "overdue", "inactive", "out of stock":
            self.style = .danger
        default:
            self.style = .neutral
        }
    }

    public init(status: String, type: BadgeStyle) {
        self.text = status
        self.style = type
    }

    public var body: some View {
        Text(text)
            .font(AppTypography.caption)
            .fontWeight(.semibold)
            .foregroundColor(style.fgColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(style.bgColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(style.borderColor, lineWidth: 1)
            )
    }
}

public typealias StatusBadgeType = StatusBadge.BadgeStyle

public extension StatusBadge.BadgeStyle {
    static var error: StatusBadge.BadgeStyle { .danger }
}

