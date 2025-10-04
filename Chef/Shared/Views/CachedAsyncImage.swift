import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    // MARK: - Properties
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var phase: AsyncImagePhase = .empty
    @State private var cachedImage: UIImage?
    
    // MARK: - Initialization
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self.placeholder = placeholder
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            switch phase {
            case .empty:
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            case .success(let image):
                content(image)
            case .failure:
                // 顯示錯誤狀態，使用系統圖標作為佔位圖
                placeholder()
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.caption)
                    )
            @unknown default:
                placeholder()
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadImage() {
        guard let url = url else {
            phase = .failure(URLError(.badURL))
            return
        }
        
        // 檢查緩存
        if let cached = cachedImage {
            phase = .success(Image(uiImage: cached))
            return
        }
        
        // 從網絡加載
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    phase = .failure(error)
                }
                return
            }
            
            guard let data = data,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    phase = .failure(URLError(.cannotDecodeContentData))
                }
                return
            }
            
            // 緩存圖片
            cachedImage = image
            
            DispatchQueue.main.async {
                withTransaction(transaction) {
                    phase = .success(Image(uiImage: image))
                }
            }
        }.resume()
    }
}

// MARK: - Convenience Initializers
extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            scale: scale,
            transaction: transaction,
            content: content,
            placeholder: { ProgressView() }
        )
    }
}

// MARK: - Preview
struct CachedAsyncImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 成功加載
            CachedAsyncImage(
                url: URL(string: "https://picsum.photos/200"),
                content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            )
            
            // 加載失敗
            CachedAsyncImage(
                url: URL(string: "https://invalid-url.com/image.jpg"),
                content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            )
            
            // 自定義佔位圖
            CachedAsyncImage(
                url: URL(string: "https://picsum.photos/200"),
                content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                },
                placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 