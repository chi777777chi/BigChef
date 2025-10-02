import UIKit

struct ImageCompressor {
    // MARK: - Constants
    private static let maxDimension: CGFloat = 800  // 降低最大尺寸
    private static let maxKB: Int = 200
    private static let maxBytes: Int = maxKB * 1024
    private static let base64Prefix = "data:image/jpeg;base64,"
    
    // MARK: - Public Methods
    
    static func compressToBase64(image: UIImage) -> String? {
        // 步驟 1: 轉換 HDR 圖片為標準圖片
        let standardImage: UIImage
        if image.scale > 1.0 {
            // 如果是 HDR 圖片，先轉換為標準圖片
            let renderer = UIGraphicsImageRenderer(size: image.size)
            standardImage = renderer.image { context in
                // 使用標準色彩空間
                context.cgContext.setFillColor(UIColor.black.cgColor)
                context.cgContext.fill(CGRect(origin: .zero, size: image.size))
                image.draw(in: CGRect(origin: .zero, size: image.size))
            }
        } else {
            standardImage = image
        }
        
        // 步驟 2: 調整圖片尺寸
        guard let resized = resize(image: standardImage, maxDimension: maxDimension) else {
            print("❌ 調整圖片尺寸失敗")
            return nil
        }
        
        // 步驟 3: 嘗試不同的壓縮策略
        let strategies: [(UIImage) -> Data?] = [
            // 策略 1: 高品質壓縮
            { $0.jpegData(compressionQuality: 0.7) },
            // 策略 2: 中等品質壓縮
            { $0.jpegData(compressionQuality: 0.5) },
            // 策略 3: 低品質壓縮
            { $0.jpegData(compressionQuality: 0.3) },
            // 策略 4: 極低品質壓縮
            { $0.jpegData(compressionQuality: 0.2) },
            // 策略 5: 最小品質壓縮
            { $0.jpegData(compressionQuality: 0.1) }
        ]
        
        // 步驟 4: 嘗試每個策略，直到找到合適的壓縮結果
        for (index, strategy) in strategies.enumerated() {
            if let data = strategy(resized), data.count <= maxBytes {
                let quality = 1.0 - (Double(index) * 0.2)
                print("✅ 圖片成功壓縮為 \(data.count / 1024) KB (品質: \(quality))")
                return base64Prefix + data.base64EncodedString()
            }
        }
        
        // 步驟 5: 如果所有策略都失敗，嘗試更激進的尺寸縮小
        let smallerDimensions: [CGFloat] = [0.75, 0.5, 0.25]  // 嘗試更小的尺寸
        for scale in smallerDimensions {
            if let smaller = resize(image: resized, maxDimension: maxDimension * scale),
               let data = smaller.jpegData(compressionQuality: 0.1),
               data.count <= maxBytes {
                print("✅ 圖片成功壓縮為 \(data.count / 1024) KB (縮小尺寸至 \(Int(scale * 100))% + 最低品質)")
                return base64Prefix + data.base64EncodedString()
            }
        }
        
        // 步驟 6: 最後嘗試，使用最小尺寸和最低品質
        if let final = resize(image: resized, maxDimension: 400),  // 使用更小的尺寸
           let data = final.jpegData(compressionQuality: 0.05),    // 使用更低的品質
           data.count <= maxBytes {
            print("✅ 圖片成功壓縮為 \(data.count / 1024) KB (最終策略：最小尺寸 + 最低品質)")
            return base64Prefix + data.base64EncodedString()
        }
        
        print("❌ 無法將圖片壓縮至 \(maxKB)KB 以下")
        return nil
    }
    
    // MARK: - Private Methods
    
    private static func resize(image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize: CGSize
        if aspectRatio > 1 {
            // 寬圖
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            // 高圖
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // 使用 UIGraphicsImageRenderer 進行高品質縮放
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            // 設置插值品質
            context.cgContext.interpolationQuality = .medium  // 使用中等品質以加快處理速度
            // 使用標準色彩空間
            context.cgContext.setFillColor(UIColor.black.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: newSize))
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
} 