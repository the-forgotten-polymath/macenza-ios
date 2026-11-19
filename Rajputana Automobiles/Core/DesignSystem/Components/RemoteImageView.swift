import SwiftUI

public struct RemoteImageView: View {
    public let urlString: String
    public var contentMode: ContentMode = .fill
    public var placeholderIcon: String = "photo"
    public var height: CGFloat? = nil
    public var cornerRadius: CGFloat = 0

    public init(
        urlString: String,
        contentMode: ContentMode = .fill,
        placeholderIcon: String = "photo",
        height: CGFloat? = nil,
        cornerRadius: CGFloat = 0
    ) {
        self.urlString = urlString
        self.contentMode = contentMode
        self.placeholderIcon = placeholderIcon
        self.height = height
        self.cornerRadius = cornerRadius
    }

    public init(
        imagePath: String,
        contentMode: ContentMode = .fill,
        placeholderIcon: String = "photo",
        height: CGFloat? = nil,
        cornerRadius: CGFloat = 0
    ) {
        self.urlString = imagePath
        self.contentMode = contentMode
        self.placeholderIcon = placeholderIcon
        self.height = height
        self.cornerRadius = cornerRadius
    }

    private var parsedUrl: URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        } else if trimmed.hasPrefix("/") {
            return URL(string: "https://api.rajputanaautomobiles.com" + trimmed)
        }
        return nil
    }

    private var dataUriImage: UIImage? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("data:image"), let commaIndex = trimmed.firstIndex(of: ",") {
            let base64String = String(trimmed[trimmed.index(after: commaIndex)...])
            if let data = Data(base64Encoded: base64String) {
                return UIImage(data: data)
            }
        }
        return nil
    }

    public var body: some View {
        Group {
            if let uiImage = dataUriImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if let url = parsedUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            AppColors.surfaceGray
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var fallbackView: some View {
        ZStack {
            AppColors.surfaceGray
            Image(systemName: placeholderIcon)
                .font(.system(size: 22))
                .foregroundColor(AppColors.textLight)
        }
    }
}
