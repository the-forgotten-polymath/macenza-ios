import SwiftUI

// ── Apple Liquid Glass Design Tokens & Components ────────────────────
// Inspired by Apple visionOS & iOS Liquid Glass material design.
// Real frosted glass with .ultraThinMaterial, specular highlights,
// rim reflections, and translucent depth blur.

public enum LiquidTheme {
    // ── Brand Royal & Electric Blues ─────────────────────────────────
    public static let primaryBlue = Color(hex: 0x2563EB)
    public static let electricBlue = Color(hex: 0x2563EB)
    public static let electricBlueLight = Color(hex: 0x3B82F6)
    public static let deepNavy = Color(hex: 0x0A192F)
    public static let darkSlate = Color(hex: 0x0F172A)
    public static let textPrimary = Color(hex: 0x0F172A)
    public static let textSecondary = Color(hex: 0x475569)
    public static let textMuted = Color(hex: 0x94A3B8)

    public static let activePillGradient = LinearGradient(
        colors: [Color(hex: 0x2563EB), Color(hex: 0x1D4ED8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // ── Neutral Canvas & Glass Surfaces ─────────────────────────────
    public static let canvasBackground = Color(hex: 0xF6F8FC)
    public static let cardBackground = Color.white
    public static let glassBorder = Color(hex: 0xE2E8F0)
    public static let glassBorderSubtle = Color(hex: 0xEDF2F7)

    // ── Card Icon Pastels ───────────────────────────────────────────
    public static let pastelOrangeBg = Color(hex: 0xFFF7ED)
    public static let pastelOrangeIcon = Color(hex: 0xEA580C)

    public static let pastelCoralBg = Color(hex: 0xFEF2F2)
    public static let pastelCoralIcon = Color(hex: 0xE11D48)

    public static let pastelPurpleBg = Color(hex: 0xFAF5FF)
    public static let pastelPurpleIcon = Color(hex: 0x7C3AED)

    public static let pastelGreenBg = Color(hex: 0xECFDF5)
    public static let pastelGreenIcon = Color(hex: 0x059669)

    public static let pastelBlueBg = Color(hex: 0xEFF6FF)
    public static let pastelBlueIcon = Color(hex: 0x2563EB)

    // ── Trend Badges ────────────────────────────────────────────────
    public static let trendGreenBg = Color(hex: 0xDCFCE7)
    public static let trendGreenText = Color(hex: 0x15803D)

    public static let trendRedBg = Color(hex: 0xFEE2E2)
    public static let trendRedText = Color(hex: 0xB91C1C)
    public static let softBlueBg = Color(hex: 0xEFF6FF)
    public static let softBlueBorder = Color(hex: 0xBFDBFE)
}

// ── Apple Liquid Glass Background Shapes ──────────────────────────────

/// Apple Tinted Liquid Glass Capsule (WWDC / visionOS Reference Parity)
/// Translucent dark-tinted frosted glass with multi-stop specular rim,
/// glossy optical reflection sheen, and deep backdrop blur.
public struct TintedLiquidGlassCapsule: View {
    public var body: some View {
        ZStack {
            // 1. Hardware Ultra-Thin Optical Blur
            Capsule()
                .fill(.ultraThinMaterial)

            // 2. Tinted Translucent Optical Body (Preserves transparency while giving high contrast)
            Capsule()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: 0x0A192F).opacity(0.70), location: 0.0),
                            .init(color: Color(hex: 0x081325).opacity(0.85), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // 3. Specular Surface Reflection (Curved Glass Sheen)
            Capsule()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.32), location: 0.0),
                            .init(color: Color.white.opacity(0.08), location: 0.35),
                            .init(color: Color.clear, location: 0.65)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // 4. Specular Beveled Rim Highlight (Apple Liquid Glass Edge)
            Capsule()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.85), location: 0.0),
                            .init(color: Color.white.opacity(0.25), location: 0.35),
                            .init(color: Color.white.opacity(0.08), location: 0.70),
                            .init(color: Color.white.opacity(0.40), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
    }
}

/// Apple Tinted Liquid Glass Circle (Matches ☰ in Apple reference)
public struct TintedLiquidGlassCircle: View {
    public var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)

            Circle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: 0x0A192F).opacity(0.70), location: 0.0),
                            .init(color: Color(hex: 0x081325).opacity(0.85), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Circle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.35), location: 0.0),
                            .init(color: Color.white.opacity(0.08), location: 0.40),
                            .init(color: Color.clear, location: 0.70)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Circle()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.90), location: 0.0),
                            .init(color: Color.white.opacity(0.30), location: 0.40),
                            .init(color: Color.white.opacity(0.10), location: 0.75),
                            .init(color: Color.white.opacity(0.45), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .shadow(color: Color.black.opacity(0.20), radius: 10, x: 0, y: 4)
    }
}

/// Translucent frosted glass capsule with specular rim lighting and blur (Light variant).
public struct LiquidGlassCapsuleBackground: View {
    public var tint: Color = Color.white.opacity(0.35)

    public init(tint: Color = Color.white.opacity(0.35)) {
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            // Native iOS Ultra Thin Blur Material
            Capsule()
                .fill(.ultraThinMaterial)

            // Specular Gradient Sheen (Glass Reflection)
            Capsule()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.45), location: 0.0),
                            .init(color: Color.white.opacity(0.12), location: 0.25),
                            .init(color: Color.clear, location: 0.65),
                            .init(color: tint, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Specular Rim Stroke (Liquid Glass Edge)
            Capsule()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.9), location: 0.0),
                            .init(color: Color.white.opacity(0.4), location: 0.35),
                            .init(color: Color.white.opacity(0.1), location: 0.7),
                            .init(color: Color.white.opacity(0.45), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

/// Translucent frosted glass circle matching the circular menu button in Apple's design.
public struct LiquidGlassCircleBackground: View {
    public var tint: Color = Color.white.opacity(0.35)

    public init(tint: Color = Color.white.opacity(0.35)) {
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)

            Circle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.5), location: 0.0),
                            .init(color: Color.white.opacity(0.12), location: 0.3),
                            .init(color: Color.clear, location: 0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Circle()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.95), location: 0.0),
                            .init(color: Color.white.opacity(0.35), location: 0.4),
                            .init(color: Color.white.opacity(0.1), location: 0.75),
                            .init(color: Color.white.opacity(0.5), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

/// Liquid glass rounded card for content containers.
public struct LiquidCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = 20

    public func body(content: Content) -> some View {
        content
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white, location: 0.0),
                                .init(color: LiquidTheme.glassBorderSubtle, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color(hex: 0x0F172A).opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

public extension View {
    func liquidCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(LiquidCardModifier(cornerRadius: cornerRadius))
    }
}

// ── Metric Card Component (Reference Parity) ─────────────────────────
public struct LiquidMetricCard: View {
    public let title: String
    public let value: String
    public let subtitle: String
    public let badgeText: String
    public let isPositive: Bool
    public let iconName: String
    public let iconBg: Color
    public let iconTint: Color
    public var onInfoTap: (() -> Void)? = nil
    public var onTap: (() -> Void)? = nil

    public init(
        title: String,
        value: String,
        subtitle: String,
        badgeText: String,
        isPositive: Bool,
        iconName: String,
        iconBg: Color,
        iconTint: Color,
        onInfoTap: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.isPositive = isPositive
        self.iconName = iconName
        self.iconBg = iconBg
        self.iconTint = iconTint
        self.onInfoTap = onInfoTap
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 10) {
                // Top Row: Title + Info icon on left, circular pastel icon on right
                HStack(alignment: .center) {
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x334155))
                            .lineLimit(1)

                        Button(action: { onInfoTap?() }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: 0x94A3B8))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Pastel Circular Icon
                    ZStack {
                        Circle()
                            .fill(iconBg)
                            .frame(width: 32, height: 32)
                        Image(systemName: iconName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(iconTint)
                    }
                }

                // Big Bold Value
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x0F172A))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                // Subtitle (e.g. "+10,508 vs last month")
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(hex: 0x64748B))
                    .lineLimit(1)

                // Trend Badge Pill (e.g. "+1.3% ↗")
                HStack {
                    HStack(spacing: 3) {
                        Text(badgeText)
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isPositive ? LiquidTheme.trendGreenBg : LiquidTheme.trendRedBg)
                    .foregroundStyle(isPositive ? LiquidTheme.trendGreenText : LiquidTheme.trendRedText)
                    .clipShape(Capsule())

                    Spacer()
                }
            }
            .padding(14)
            .liquidCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}
