//
//  ActionButtonView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import SwiftUI

// MARK: - 統一樣式的動作按鈕元件
struct ActionButtonView: View {
    let title: String
    let icon: String
    let style: ActionButtonStyle
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    // 初始化預設值
    init(
        title: String,
        icon: String,
        style: ActionButtonStyle = .primary,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                action()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Image(systemName: icon)
                        .font(.title3)
                }

                Text(isLoading ? "處理中..." : title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .foregroundColor(style.foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }

    // 計算背景顏色
    private var backgroundColor: Color {
        if !isEnabled && !isLoading {
            return Color.gray.opacity(0.3)
        }

        switch style {
        case .primary:
            return Color.brandOrange
        case .secondary:
            return Color.brandOrange.opacity(0.15)
        case .destructive:
            return Color.red
        case .success:
            return Color.green
        }
    }
}

// MARK: - 按鈕樣式枚舉
enum ActionButtonStyle {
    case primary    // 主要按鈕（橙色背景）
    case secondary  // 次要按鈕（橙色邊框）
    case destructive // 危險按鈕（紅色背景）
    case success    // 成功按鈕（綠色背景）

    var foregroundColor: Color {
        switch self {
        case .primary, .destructive, .success:
            return .white
        case .secondary:
            return .brandOrange
        }
    }
}

// MARK: - 預設樣式的快捷建構子
extension ActionButtonView {
    /// 主要動作按鈕
    static func primary(
        title: String,
        icon: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> ActionButtonView {
        ActionButtonView(
            title: title,
            icon: icon,
            style: .primary,
            isEnabled: isEnabled,
            isLoading: isLoading,
            action: action
        )
    }

    /// 次要動作按鈕
    static func secondary(
        title: String,
        icon: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> ActionButtonView {
        ActionButtonView(
            title: title,
            icon: icon,
            style: .secondary,
            isEnabled: isEnabled,
            action: action
        )
    }

    /// 危險動作按鈕
    static func destructive(
        title: String,
        icon: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> ActionButtonView {
        ActionButtonView(
            title: title,
            icon: icon,
            style: .destructive,
            isEnabled: isEnabled,
            action: action
        )
    }

    /// 成功動作按鈕
    static func success(
        title: String,
        icon: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> ActionButtonView {
        ActionButtonView(
            title: title,
            icon: icon,
            style: .success,
            isEnabled: isEnabled,
            action: action
        )
    }
}

// MARK: - 預覽
#Preview {
    VStack(spacing: 16) {
        ActionButtonView.primary(
            title: "開始辨識",
            icon: "magnifyingglass",
            action: {}
        )

        ActionButtonView.secondary(
            title: "重新選擇",
            icon: "photo",
            action: {}
        )

        ActionButtonView.destructive(
            title: "刪除",
            icon: "trash",
            action: {}
        )

        ActionButtonView.success(
            title: "使用食材",
            icon: "checkmark",
            action: {}
        )

        ActionButtonView.primary(
            title: "辨識中",
            icon: "magnifyingglass",
            isLoading: true,
            action: {}
        )

        ActionButtonView.primary(
            title: "無法使用",
            icon: "magnifyingglass",
            isEnabled: false,
            action: {}
        )
    }
    .padding()
}