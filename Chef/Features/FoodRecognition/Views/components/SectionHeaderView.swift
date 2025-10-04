//
//  SectionHeaderView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import SwiftUI

// MARK: - 區塊標題元件
struct SectionHeaderView: View {
    let title: String
    let icon: String?
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?

    // 預設初始化
    init(
        title: String,
        icon: String? = nil,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.action = action
        self.actionTitle = actionTitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 標題區域
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(.brandOrange)
                    }

                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Spacer()

                // 動作按鈕
                if let action = action, let actionTitle = actionTitle {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.brandOrange)
                    }
                }
            }

            // 副標題
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 快捷建構子
extension SectionHeaderView {
    /// 僅標題的標頭
    static func title(_ title: String) -> SectionHeaderView {
        SectionHeaderView(title: title)
    }

    /// 帶圖示的標頭
    static func titleWithIcon(
        title: String,
        icon: String
    ) -> SectionHeaderView {
        SectionHeaderView(title: title, icon: icon)
    }

    /// 帶副標題的標頭
    static func titleWithSubtitle(
        title: String,
        subtitle: String,
        icon: String? = nil
    ) -> SectionHeaderView {
        SectionHeaderView(title: title, icon: icon, subtitle: subtitle)
    }

    /// 帶動作按鈕的標頭
    static func titleWithAction(
        title: String,
        icon: String? = nil,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> SectionHeaderView {
        SectionHeaderView(
            title: title,
            icon: icon,
            actionTitle: actionTitle,
            action: action
        )
    }

    /// 完整配置的標頭
    static func full(
        title: String,
        icon: String,
        subtitle: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> SectionHeaderView {
        SectionHeaderView(
            title: title,
            icon: icon,
            subtitle: subtitle,
            actionTitle: actionTitle,
            action: action
        )
    }
}

// MARK: - 預覽
#Preview {
    VStack(spacing: 24) {
        SectionHeaderView.title("基本標題")

        SectionHeaderView.titleWithIcon(
            title: "帶圖示標題",
            icon: "star.fill"
        )

        SectionHeaderView.titleWithSubtitle(
            title: "辨識結果",
            subtitle: "AI 已成功辨識出以下食物和食材",
            icon: "checkmark.circle.fill"
        )

        SectionHeaderView.titleWithAction(
            title: "可能的食材",
            icon: "list.bullet",
            actionTitle: "全部選擇"
        ) {
            print("全部選擇")
        }

        SectionHeaderView.full(
            title: "完整標頭",
            icon: "gear",
            subtitle: "這是一個包含所有元素的標頭範例",
            actionTitle: "編輯"
        ) {
            print("編輯動作")
        }
    }
    .padding()
}