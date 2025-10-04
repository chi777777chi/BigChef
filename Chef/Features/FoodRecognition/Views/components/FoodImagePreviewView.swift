//
//  FoodImagePreviewView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import SwiftUI

// MARK: - 圖片預覽元件
struct FoodImagePreviewView: View {
    let image: UIImage
    let showImageInfo: Bool
    let onReselect: () -> Void
    let onRemove: (() -> Void)?

    @State private var showFullScreen = false

    init(
        image: UIImage,
        showImageInfo: Bool = true,
        onReselect: @escaping () -> Void,
        onRemove: (() -> Void)? = nil
    ) {
        self.image = image
        self.showImageInfo = showImageInfo
        self.onReselect = onReselect
        self.onRemove = onRemove
    }

    var body: some View {
        VStack(spacing: 16) {
            // 圖片預覽區域
            imagePreviewSection

            // 圖片資訊（如果啟用）
            if showImageInfo {
                imageInfoSection
            }

            // 動作按鈕
            actionButtonsSection
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .fullScreenCover(isPresented: $showFullScreen) {
            fullScreenImageView
        }
    }

    // MARK: - 子視圖

    private var imagePreviewSection: some View {
        VStack(spacing: 12) {
            Text("已選擇圖片")
                .font(.headline)
                .foregroundColor(.brandOrange)

            Button(action: {
                showFullScreen = true
            }) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                    .overlay(
                        // 放大圖示覆蓋層
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                            .opacity(0)
                            .overlay(
                                Image(systemName: "magnifyingglass")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .opacity(0)
                            )
                            .onHover { isHovering in
                                // 在 iOS 上不會觸發，但保留用於未來 macOS 支援
                            }
                    )
            }
            .buttonStyle(PlainButtonStyle())

            Text("點擊圖片可放大查看")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var imageInfoSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("圖片資訊")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }

            VStack(spacing: 4) {
                imageInfoRow(label: "尺寸", value: imageSizeText)
                imageInfoRow(label: "格式", value: "JPEG")
                imageInfoRow(label: "預估大小", value: estimatedSizeText)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // 重新選擇按鈕
            ActionButtonView.secondary(
                title: "重新選擇圖片",
                icon: "photo.on.rectangle",
                action: onReselect
            )

            // 移除按鈕（如果提供）
            if let onRemove = onRemove {
                ActionButtonView.destructive(
                    title: "移除圖片",
                    icon: "trash",
                    action: onRemove
                )
            }
        }
    }

    private var fullScreenImageView: some View {
        NavigationView {
            ZoomableImageView(image: image)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            showFullScreen = false
                        }
                        .foregroundColor(.brandOrange)
                    }
                }
        }
    }

    // MARK: - 輔助視圖

    private func imageInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }

    // MARK: - 計算屬性

    private var imageSizeText: String {
        "\(Int(image.size.width)) × \(Int(image.size.height))"
    }

    private var estimatedSizeText: String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            return "未知"
        }
        let sizeInMB = Double(data.count) / (1024 * 1024)
        if sizeInMB < 1.0 {
            let sizeInKB = Double(data.count) / 1024
            return String(format: "%.0f KB", sizeInKB)
        } else {
            return String(format: "%.1f MB", sizeInMB)
        }
    }
}

// MARK: - 可縮放圖片視圖
private struct ZoomableImageView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                            // 限制縮放範圍
                            if scale < 0.5 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    scale = 0.5
                                    lastScale = 0.5
                                }
                            } else if scale > 3.0 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    scale = 3.0
                                    lastScale = 3.0
                                }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    // 雙擊重置縮放
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scale = 1.0
                        lastScale = 1.0
                    }
                }
        }
        .background(Color.black)
    }
}

// MARK: - 預覽
#Preview {
    // 創建一個模擬圖片用於預覽
    let sampleImage = UIImage(systemName: "photo.fill")?.withTintColor(.gray, renderingMode: .alwaysOriginal) ?? UIImage()

    FoodImagePreviewView(
        image: sampleImage,
        onReselect: {
            print("重新選擇圖片")
        },
        onRemove: {
            print("移除圖片")
        }
    )
    .padding()
}