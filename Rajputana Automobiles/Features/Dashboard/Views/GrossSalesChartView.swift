import SwiftUI

public struct GrossSalesChartView: View {
    public let data: [GrossSalesPoint]
    @State private var selectedIndex: Int? = nil

    private let yLabels: [Double] = [150, 120, 90, 60, 30, 0]
    private let maxY: Double = 150.0

    public init(data: [GrossSalesPoint]) {
        self.data = data
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Card Title
            HStack {
                Text("Gross Sales Trends")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
                Spacer()
            }

            if data.isEmpty {
                VStack {
                    Spacer()
                    Text("No sales data available")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: 0x94A3B8))
                    Spacer()
                }
                .frame(height: 220)
            } else {
                VStack(spacing: 0) {
                    // Tooltip if point selected
                    if let idx = selectedIndex, idx < data.count {
                        let pt = data[idx]
                        HStack(spacing: 12) {
                            Text(pt.monthLabel)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: 0x0F172A))
                            HStack(spacing: 4) {
                                Circle().fill(Color(hex: 0x2F6BDE)).frame(width: 6, height: 6)
                                Text(String(format: "Actual: ₹%.1fL", pt.revenueInLakhs))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: 0x2F6BDE))
                            }
                            HStack(spacing: 4) {
                                Circle().stroke(Color(hex: 0x00C896), lineWidth: 1.5).frame(width: 6, height: 6)
                                Text(String(format: "Target: ₹%.1fL", pt.targetInLakhs))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: 0x00C896))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: 0xF8FAFC))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(hex: 0xE2E8F0), lineWidth: 1))
                        .padding(.bottom, 6)
                    }

                    // Main Chart Area
                    GeometryReader { geo in
                        let leftPadding: CGFloat = 36
                        let rightPadding: CGFloat = 16
                        let topPadding: CGFloat = 12
                        let bottomPadding: CGFloat = 26
                        let chartWidth = max(10, geo.size.width - leftPadding - rightPadding)
                        let chartHeight = max(10, geo.size.height - topPadding - bottomPadding)

                        ZStack(alignment: .topLeading) {
                            // ── Horizontal Grid Lines & Y Labels ─────────────
                            ForEach(yLabels, id: \.self) { yVal in
                                let yPos = topPadding + chartHeight * CGFloat(1.0 - (yVal / maxY))

                                // Grid Line
                                Path { path in
                                    path.move(to: CGPoint(x: leftPadding, y: yPos))
                                    path.addLine(to: CGPoint(x: leftPadding + chartWidth, y: yPos))
                                }
                                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)

                                // Label
                                Text("\(Int(yVal))L")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(hex: 0x94A3B8))
                                    .position(x: leftPadding / 2, y: yPos)
                            }

                            // ── Vertical Indicator Line (if tapped) ──────────
                            if let idx = selectedIndex, idx < data.count, data.count > 1 {
                                let step = chartWidth / CGFloat(data.count - 1)
                                let x = leftPadding + CGFloat(idx) * step

                                Path { path in
                                    path.move(to: CGPoint(x: x, y: topPadding))
                                    path.addLine(to: CGPoint(x: x, y: topPadding + chartHeight))
                                }
                                .stroke(Color(hex: 0x94A3B8).opacity(0.8), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            }

                            // ── Green Target Line (Dashed + Hollow Circles + Area Fill)
                            if data.count > 1 {
                                let targetPoints = points(for: data.map { $0.targetInLakhs }, width: chartWidth, height: chartHeight, left: leftPadding, top: topPadding)

                                // Area Fill
                                targetAreaPath(points: targetPoints, bottomY: topPadding + chartHeight)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: 0x00C896).opacity(0.12), Color(hex: 0x00C896).opacity(0.01)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                // Line
                                curvedPath(points: targetPoints)
                                    .stroke(
                                        Color(hex: 0x00C896),
                                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [6, 4])
                                    )

                                // Hollow Dots
                                ForEach(0..<targetPoints.count, id: \.self) { i in
                                    let pt = targetPoints[i]
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 9, height: 9)
                                        .overlay(Circle().stroke(Color(hex: 0x00C896), lineWidth: 2))
                                        .position(pt)
                                }
                            }

                            // ── Blue Revenue Line (Solid + Filled Circles + Gradient Fill)
                            if data.count > 1 {
                                let revPoints = points(for: data.map { $0.revenueInLakhs }, width: chartWidth, height: chartHeight, left: leftPadding, top: topPadding)

                                // Gradient Area Fill
                                targetAreaPath(points: revPoints, bottomY: topPadding + chartHeight)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: 0x2F6BDE).opacity(0.35), Color(hex: 0x2F6BDE).opacity(0.02)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                // Solid Line
                                curvedPath(points: revPoints)
                                    .stroke(
                                        Color(hex: 0x2F6BDE),
                                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                                    )

                                // Filled Dots
                                ForEach(0..<revPoints.count, id: \.self) { i in
                                    let pt = revPoints[i]
                                    Circle()
                                        .fill(Color(hex: 0x2F6BDE))
                                        .frame(width: 8, height: 8)
                                        .position(pt)
                                }
                            }

                            // ── X-Axis Month Labels ──────────────────────────
                            if data.count > 1 {
                                let step = chartWidth / CGFloat(data.count - 1)
                                ForEach(0..<data.count, id: \.self) { i in
                                    let x = leftPadding + CGFloat(i) * step
                                    let y = topPadding + chartHeight + 14
                                    Text(data[i].monthLabel)
                                        .font(.system(size: 11, weight: selectedIndex == i ? .bold : .medium))
                                        .foregroundColor(selectedIndex == i ? Color(hex: 0x0F172A) : Color(hex: 0x94A3B8))
                                        .position(x: x, y: y)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let touchX = value.location.x - leftPadding
                                    if data.count > 1 && touchX >= 0 && touchX <= chartWidth {
                                        let step = chartWidth / CGFloat(data.count - 1)
                                        let idx = Int(round(touchX / step))
                                        self.selectedIndex = max(0, min(data.count - 1, idx))
                                    }
                                }
                        )
                    }
                    .frame(height: 220)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xF1F5F9), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }

    private func points(for values: [Double], width: CGFloat, height: CGFloat, left: CGFloat, top: CGFloat) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let step = width / CGFloat(values.count - 1)
        return values.enumerated().map { i, val in
            let clamped = max(0, min(maxY, val))
            let x = left + CGFloat(i) * step
            let y = top + height * CGFloat(1.0 - (clamped / maxY))
            return CGPoint(x: x, y: y)
        }
    }

    private func curvedPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        path.move(to: points[0])

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let midX = (prev.x + curr.x) / 2
            let cp1 = CGPoint(x: midX, y: prev.y)
            let cp2 = CGPoint(x: midX, y: curr.y)
            path.addCurve(to: curr, control1: cp1, control2: cp2)
        }
        return path
    }

    private func targetAreaPath(points: [CGPoint], bottomY: CGFloat) -> Path {
        var path = Path()
        guard points.count > 1, let first = points.first, let last = points.last else { return path }
        path.move(to: CGPoint(x: first.x, y: bottomY))
        path.addLine(to: first)

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let midX = (prev.x + curr.x) / 2
            let cp1 = CGPoint(x: midX, y: prev.y)
            let cp2 = CGPoint(x: midX, y: curr.y)
            path.addCurve(to: curr, control1: cp1, control2: cp2)
        }

        path.addLine(to: CGPoint(x: last.x, y: bottomY))
        path.closeSubpath()
        return path
    }
}
