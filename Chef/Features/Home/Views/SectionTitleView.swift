//
//  SectionTitleView.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/8.
//
import SwiftUI

struct SectionTitleView: View {
    // MARK: - Properties
    let title: String
    let showSeeAll: Bool
    let onSeeAllTapped: (() -> Void)?
    
    // MARK: - Initialization
    init(
        title: String,
        showSeeAll: Bool = true,
        onSeeAllTapped: (() -> Void)? = nil
    ) {
        self.title = title
        self.showSeeAll = showSeeAll
        self.onSeeAllTapped = onSeeAllTapped
    }
    
    // MARK: - Body
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            if showSeeAll {
                Button(action: { onSeeAllTapped?() }) {
                    Text("查看全部")
                        .foregroundColor(.pink)
                }
            }
        }
    }
}

// MARK: - Preview
struct SectionTitleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SectionTitleView(title: "測試標題")
            SectionTitleView(title: "無查看全部按鈕", showSeeAll: false)
            SectionTitleView(
                title: "可點擊的標題",
                onSeeAllTapped: { print("查看全部被點擊") }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
