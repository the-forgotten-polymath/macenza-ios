import SwiftUI

public struct AgingPieChartView: View {
    public let segments: [AgingChartSegment]
    public let totalOutstanding: Double
    @State private var selectedSliceIndex: Int? = nil

    public init(segments: [AgingChartSegment], totalOutstanding: Double) {
        self.segments = segments
        self.totalOutstanding = totalOutstanding
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            VStack(alignment: .leading, spacing: 3) {
                Text("Outstanding Aging Analysis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
                Text("Collection breakdown by due terms")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: 0x64748B))
            }

            Divider()
                .background(Color(hex: 0xF1F5F9))

            // ── Donut Chart ───────────────────────────────────────
            ZStack {
                donutRing
                    .frame(width: 220, height: 220)

                // Center Text
                VStack(spacing: 3) {
                    Text("TOTAL RECEIVABLES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: 0x64748B))
                        .tracking(0.3)

                    Text(formatCenterAmount(totalOutstanding))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: 0x0F172A))

                    Text("3 Aging Tiers")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: 0x64748B))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0xF1F5F9))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

            // ── 3 Aging Tiers Progress Rows ─────────────────────────
            VStack(spacing: 12) {
                ForEach(0..<segments.count, id: \.self) { idx in
                    tierProgressRow(segments[idx])
                }
            }

            Divider()
                .background(Color(hex: 0xF1F5F9))

            // ── Summary Footer Row ──────────────────────────────────
            let overduePct = segments.first(where: { $0.label.contains("60+") })?.percentage ?? 20.0
            let currentPct = segments.first(where: { $0.label.contains("0–30") || $0.label.contains("0-30") })?.percentage ?? 45.0

            HStack {
                Text("Overdue Risk (60+ Days): \(Int(round(overduePct)))%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0xDC2626))

                Spacer()

                Text("\(Int(round(currentPct)))% Current")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x059669))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xECFDF5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xF1F5F9), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }

    // ── Donut Canvas ──────────────────────────────────────────────
    private var donutRing: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 12
            let strokeWidth: CGFloat = 28
            let gapDegrees: Double = 3.0
            let sum = segments.reduce(0.0) { $0 + $1.percentage }

            ZStack {
                ForEach(0..<segments.count, id: \.self) { i in
                    let seg = segments[i]
                    let sliceDegrees = sum > 0 ? (seg.percentage / sum) * 360.0 : 120.0
                    let startDeg = startAngle(for: i, in: segments, sum: sum) + gapDegrees / 2
                    let sweepDeg = max(1.0, sliceDegrees - gapDegrees)

                    ArcSliceShape(
                        center: center,
                        radius: selectedSliceIndex == i ? radius + 4 : radius,
                        startAngle: Angle(degrees: startDeg - 90),
                        sweepAngle: Angle(degrees: sweepDeg),
                        lineWidth: selectedSliceIndex == i ? strokeWidth + 4 : strokeWidth
                    )
                    .stroke(seg.color, style: StrokeStyle(lineWidth: selectedSliceIndex == i ? strokeWidth + 4 : strokeWidth, lineCap: .butt))
                }
            }
        }
    }

    private func startAngle(for index: Int, in list: [AgingChartSegment], sum: Double) -> Double {
        var angle = 0.0
        for i in 0..<index {
            let deg = sum > 0 ? (list[i].percentage / sum) * 360.0 : 120.0
            angle += deg
        }
        return angle
    }

    // ── Tier Progress Row ─────────────────────────────────────────
    private func tierProgressRow(_ segment: AgingChartSegment) -> some View {
        let (badgeText, badgeBg, badgeTextColor): (String, Color, Color) = {
            if segment.label.contains("0–30") || segment.label.contains("0-30") {
                return ("Healthy", Color(hex: 0xECFDF5), Color(hex: 0x059669))
            } else if segment.label.contains("31–60") || segment.label.contains("31-60") {
                return ("Due Soon", Color(hex: 0xFFFBEB), Color(hex: 0xD97706))
            } else {
                return ("Critical Overdue", Color(hex: 0xFEF2F2), Color(hex: 0xDC2626))
            }
        }()

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 6) {
                Circle()
                    .fill(segment.color)
                    .frame(width: 8, height: 8)

                Text(segment.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))

                Text(badgeText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(badgeTextColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(badgeBg)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                Text("\(formatIndianFull(segment.amount)) (\(Int(round(segment.percentage)))%)")
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(Color(hex: 0x0F172A))
            }

            // Progress Bar Track
            GeometryReader { barGeo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: 0xF1F5F9))
                        .frame(height: 6)

                    let progressRatio = max(0.02, min(1.0, segment.percentage / 100.0))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(segment.color)
                        .frame(width: barGeo.size.width * CGFloat(progressRatio), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }

    private func formatCenterAmount(_ amount: Double) -> String {
        let absVal = abs(amount)
        if absVal >= 10_000_000 {
            return String(format: "₹%.2fCr", amount / 10_000_000)
        } else if absVal >= 100_000 {
            return String(format: "₹%.2fL", amount / 100_000)
        } else if absVal >= 1_000 {
            return String(format: "₹%.1fK", amount / 1_000)
        } else {
            return String(format: "₹%.0f", amount)
        }
    }

    private func formatIndianFull(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "₹%.2f", amount)
    }
}

// ── Custom Arc Shape ──────────────────────────────────────────────
struct ArcSliceShape: Shape {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: Angle
    let sweepAngle: Angle
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: startAngle + sweepAngle,
            clockwise: false
        )
        return path
    }
}
