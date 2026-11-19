import SwiftUI

public struct DealerCard: View {
    public let customer: Customer
    public var onCardClick: () -> Void = {}
    public var onEditClick: () -> Void = {}
    public var onStatementClick: () -> Void = {}
    public var onDeleteClick: () -> Void = {}

    private let avatarPalette: [Color] = [
        Color(hex: 0x0E9F6E), // Green
        Color(hex: 0x2563EB), // Blue
        Color(hex: 0x4F46E5), // Indigo / Purple
        Color(hex: 0xDB2777)  // Pink
    ]

    public init(
        customer: Customer,
        onCardClick: @escaping () -> Void = {},
        onEditClick: @escaping () -> Void = {},
        onStatementClick: @escaping () -> Void = {},
        onDeleteClick: @escaping () -> Void = {}
    ) {
        self.customer = customer
        self.onCardClick = onCardClick
        self.onEditClick = onEditClick
        self.onStatementClick = onStatementClick
        self.onDeleteClick = onDeleteClick
    }

    private var avatarColor: Color {
        let hash = abs(customer.id.hashValue)
        return avatarPalette[hash % avatarPalette.count]
    }

    private var initials: String {
        let words = customer.name.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        if words.isEmpty { return "CU" }
        if words.count == 1 {
            return String(words[0].prefix(2)).uppercased()
        }
        let first = words[0].prefix(1)
        let second = words[1].prefix(1)
        return "\(first)\(second)".uppercased()
    }

    private var locationText: String {
        let parts = [customer.city, customer.state]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? "Location not available" : parts.joined(separator: ", ")
    }

    private var fullAddressText: String {
        let parts = [customer.address, customer.city, customer.pincode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? "Address not available" : parts.joined(separator: ", ")
    }

    private var formattedBalance: String {
        let bal = customer.effectiveBalance
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let str = formatter.string(from: NSNumber(value: abs(bal))) ?? "\(abs(bal))"
        if bal < 0 {
            return "-₹\(str)"
        } else {
            return "₹\(str)"
        }
    }

    public var body: some View {
        Button(action: onCardClick) {
            VStack(alignment: .leading, spacing: 14) {
                // ── 1. Top Tags & 3-Dots Menu ─────────────────────
                HStack(alignment: .center, spacing: 8) {
                    let codeText = customer.code.trimmingCharacters(in: .whitespacesAndNewlines)
                    Text(codeText.isEmpty ? "—" : codeText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: 0x475569))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color(hex: 0xF1F5F9))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    let groupText = (customer.group ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    Text(groupText.isEmpty ? "Uncategorized" : groupText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: 0x4F46E5))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color(hex: 0xEEF2FF))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .lineLimit(1)

                    Spacer()

                    // 3-Dots Overflow Menu
                    Menu {
                        Button {
                            onEditClick()
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }

                        Button {
                            onStatementClick()
                        } label: {
                            Label("View Statement", systemImage: "doc.text")
                        }

                        Button(role: .destructive) {
                            onDeleteClick()
                        } label: {
                            Label("Delete Customer", systemImage: "trash")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: 0xF1F5F9))
                                .frame(width: 32, height: 32)

                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: 0x64748B))
                        }
                    }
                }

                // ── 2. Avatar & Name ──────────────────────────────
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(avatarColor)
                            .frame(width: 48, height: 48)

                        Text(initials)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(customer.name.isEmpty ? "Unnamed Customer" : customer.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)

                        Text(locationText)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: 0x64748B))
                            .lineLimit(1)
                    }

                    Spacer()
                }

                // ── 3. Contact & Address Box ──────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "phone")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: 0x94A3B8))
                            .frame(width: 16)

                        let phoneStr = (customer.phone ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        Text(phoneStr.isEmpty ? "No phone number" : phoneStr)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: 0x94A3B8))
                            .frame(width: 16)
                            .padding(.top, 2)

                        Text(fullAddressText)
                            .font(.system(size: 13, weight: .regular))
                            .lineSpacing(2)
                            .foregroundColor(Color(hex: 0x475569))
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: 0xF8FAFC))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // ── 4. Outstanding Balance Box ───────────────────
                HStack {
                    Text("Outstanding Balance")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: 0x64748B))

                    Spacer()

                    Text(formattedBalance)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: 0xDC2626))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color(hex: 0xF8FAFC))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
