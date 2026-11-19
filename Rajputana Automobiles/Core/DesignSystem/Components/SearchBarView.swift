import SwiftUI

public struct SearchBarView: View {
    @Binding public var text: String
    public var placeholder: String = "Search..."
    public var onClear: (() -> Void)? = nil

    public init(text: Binding<String>, placeholder: String = "Search...", onClear: (() -> Void)? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.onClear = onClear
    }

    public init(searchText: Binding<String>, placeholder: String = "Search...", onClear: (() -> Void)? = nil) {
        self._text = searchText
        self.placeholder = placeholder
        self.onClear = onClear
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textMuted)
                .font(.system(size: 16))

            TextField(placeholder, text: $text)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textDark)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onClear?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textLight)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppColors.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}
